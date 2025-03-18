/*
 * INF560
 *
 * Image Filtering Project
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

// CUDA-specific headers
#include <cuda.h>



#include "gif_lib.h"


/* Set this macro to 1 to enable debugging information */
#define SOBELF_DEBUG 0

/* Set this macro to 1 to print the time taken by each step */
#define PRINT_TIME 0

/* Represent one pixel from the image */
typedef struct pixel
{
    int r ; /* Red */
    int g ; /* Green */
    int b ; /* Blue */
} pixel ;

/* Represent one GIF image (animated or not */
typedef struct animated_gif
{
    int n_images ; /* Number of images */
    int * width ; /* Width of each image */
    int * height ; /* Height of each image */
    pixel ** p ; /* Pixels of each image */
    GifFileType * g ; /* Internal representation.
                         DO NOT MODIFY */
} animated_gif ;

/*
 * Load a GIF image from a file and return a
 * structure of type animated_gif.
 */
animated_gif *
load_pixels( char * filename ) 
{
    GifFileType * g ;
    ColorMapObject * colmap ;
    int error ;
    int n_images ;
    int * width ;
    int * height ;
    pixel ** p ;
    int i ;
    animated_gif * image ;

    /* Open the GIF image (read mode) */
    g = DGifOpenFileName( filename, &error ) ;
    if ( g == NULL ) 
    {
        fprintf( stderr, "Error DGifOpenFileName %s\n", filename ) ;
        return NULL ;
    }

    /* Read the GIF image */
    error = DGifSlurp( g ) ;
    if ( error != GIF_OK )
    {
        fprintf( stderr, 
                "Error DGifSlurp: %d <%s>\n", error, GifErrorString(g->Error) ) ;
        return NULL ;
    }

    /* Grab the number of images and the size of each image */
    n_images = g->ImageCount ;

    width = (int *)malloc( n_images * sizeof( int ) ) ;
    if ( width == NULL )
    {
        fprintf( stderr, "Unable to allocate width of size %d\n",
                n_images ) ;
        return 0 ;
    }

    height = (int *)malloc( n_images * sizeof( int ) ) ;
    if ( height == NULL )
    {
        fprintf( stderr, "Unable to allocate height of size %d\n",
                n_images ) ;
        return 0 ;
    }

    /* Fill the width and height */
    for ( i = 0 ; i < n_images ; i++ ) 
    {
        width[i] = g->SavedImages[i].ImageDesc.Width ;
        height[i] = g->SavedImages[i].ImageDesc.Height ;

#if SOBELF_DEBUG
        printf( "Image %d: l:%d t:%d w:%d h:%d interlace:%d localCM:%p\n",
                i, 
                g->SavedImages[i].ImageDesc.Left,
                g->SavedImages[i].ImageDesc.Top,
                g->SavedImages[i].ImageDesc.Width,
                g->SavedImages[i].ImageDesc.Height,
                g->SavedImages[i].ImageDesc.Interlace,
                g->SavedImages[i].ImageDesc.ColorMap
                ) ;
#endif
    }


    /* Get the global colormap */
    colmap = g->SColorMap ;
    if ( colmap == NULL ) 
    {
        fprintf( stderr, "Error global colormap is NULL\n" ) ;
        return NULL ;
    }

#if SOBELF_DEBUG
    printf( "Global color map: count:%d bpp:%d sort:%d\n",
            g->SColorMap->ColorCount,
            g->SColorMap->BitsPerPixel,
            g->SColorMap->SortFlag
            ) ;
#endif

    /* Allocate the array of pixels to be returned */
    p = (pixel **)malloc( n_images * sizeof( pixel * ) ) ;
    if ( p == NULL )
    {
        fprintf( stderr, "Unable to allocate array of %d images\n",
                n_images ) ;
        return NULL ;
    }

    for ( i = 0 ; i < n_images ; i++ ) 
    {
        p[i] = (pixel *)malloc( width[i] * height[i] * sizeof( pixel ) ) ;
        if ( p[i] == NULL )
        {
        fprintf( stderr, "Unable to allocate %d-th array of %d pixels\n",
                i, width[i] * height[i] ) ;
        return NULL ;
        }
    }
    
    /* Fill pixels */
    /////////////////// Possibility to parallelize this loop ///////////////////
    /* For each image */
    for ( i = 0 ; i < n_images ; i++ )
    {
        int j ;

        /* Get the local colormap if needed */
        if ( g->SavedImages[i].ImageDesc.ColorMap )
        {

            /* TODO No support for local color map */
            fprintf( stderr, "Error: application does not support local colormap\n" ) ;
            return NULL ;

            colmap = g->SavedImages[i].ImageDesc.ColorMap ;
        }

        /* Traverse the image and fill pixels */
        for ( j = 0 ; j < width[i] * height[i] ; j++ ) 
        {
            int c ;

            c = g->SavedImages[i].RasterBits[j] ;

            p[i][j].r = colmap->Colors[c].Red ;
            p[i][j].g = colmap->Colors[c].Green ;
            p[i][j].b = colmap->Colors[c].Blue ;
        }
    }

    /* Allocate image info */
    image = (animated_gif *)malloc( sizeof(animated_gif) ) ;
    if ( image == NULL ) 
    {
        fprintf( stderr, "Unable to allocate memory for animated_gif\n" ) ;
        return NULL ;
    }

    /* Fill image fields */
    image->n_images = n_images ;
    image->width = width ;
    image->height = height ;
    image->p = p ;
    image->g = g ;

#if SOBELF_DEBUG
    printf( "-> GIF w/ %d image(s) with first image of size %d x %d\n",
            image->n_images, image->width[0], image->height[0] ) ;
#endif

    return image ;
}

















int 
output_modified_read_gif( char * filename, GifFileType * g ) 
{
    GifFileType * g2 ;
    int error2 ;

#if SOBELF_DEBUG
    printf( "Starting output to file %s\n", filename ) ;
#endif

    g2 = EGifOpenFileName( filename, false, &error2 ) ;
    if ( g2 == NULL )
    {
        fprintf( stderr, "Error EGifOpenFileName %s\n",
                filename ) ;
        return 0 ;
    }

    g2->SWidth = g->SWidth ;
    g2->SHeight = g->SHeight ;
    g2->SColorResolution = g->SColorResolution ;
    g2->SBackGroundColor = g->SBackGroundColor ;
    g2->AspectByte = g->AspectByte ;
    g2->SColorMap = g->SColorMap ;
    g2->ImageCount = g->ImageCount ;
    g2->SavedImages = g->SavedImages ;
    g2->ExtensionBlockCount = g->ExtensionBlockCount ;
    g2->ExtensionBlocks = g->ExtensionBlocks ;

    error2 = EGifSpew( g2 ) ;
    if ( error2 != GIF_OK ) 
    {
        fprintf( stderr, "Error after writing g2: %d <%s>\n", 
                error2, GifErrorString(g2->Error) ) ;
        return 0 ;
    }

    return 1 ;
}










///////////// Possibility to parallelize this function ///////////////////
int
store_pixels( char * filename, animated_gif * image )
{
    int n_colors = 0 ;
    pixel ** p ;
    int i, j, k ;
    GifColorType * colormap ;

    /* Initialize the new set of colors */
    colormap = (GifColorType *)malloc( 256 * sizeof( GifColorType ) ) ;
    if ( colormap == NULL ) 
    {
        fprintf( stderr,
                "Unable to allocate 256 colors\n" ) ;
        return 0 ;
    }

    /* Everything is white by default */
    for ( i = 0 ; i < 256 ; i++ ) 
    {
        colormap[i].Red = 255 ;
        colormap[i].Green = 255 ;
        colormap[i].Blue = 255 ;
    }

    /* Change the background color and store it */
    int moy ;
    moy = (
            image->g->SColorMap->Colors[ image->g->SBackGroundColor ].Red
            +
            image->g->SColorMap->Colors[ image->g->SBackGroundColor ].Green
            +
            image->g->SColorMap->Colors[ image->g->SBackGroundColor ].Blue
            )/3 ;
    if ( moy < 0 ) moy = 0 ;
    if ( moy > 255 ) moy = 255 ;

#if SOBELF_DEBUG
    printf( "[DEBUG] Background color (%d,%d,%d) -> (%d,%d,%d)\n",
            image->g->SColorMap->Colors[ image->g->SBackGroundColor ].Red,
            image->g->SColorMap->Colors[ image->g->SBackGroundColor ].Green,
            image->g->SColorMap->Colors[ image->g->SBackGroundColor ].Blue,
            moy, moy, moy ) ;
#endif

    colormap[0].Red = moy ;
    colormap[0].Green = moy ;
    colormap[0].Blue = moy ;

    image->g->SBackGroundColor = 0 ;

    n_colors++ ;

    /* Process extension blocks in main structure */
    for ( j = 0 ; j < image->g->ExtensionBlockCount ; j++ )
    {
        int f ;

        f = image->g->ExtensionBlocks[j].Function ;
        if ( f == GRAPHICS_EXT_FUNC_CODE )
        {
            int tr_color = image->g->ExtensionBlocks[j].Bytes[3] ;

            if ( tr_color >= 0 &&
                    tr_color < 255 )
            {

                int found = -1 ;

                moy = 
                    (
                     image->g->SColorMap->Colors[ tr_color ].Red
                     +
                     image->g->SColorMap->Colors[ tr_color ].Green
                     +
                     image->g->SColorMap->Colors[ tr_color ].Blue
                    ) / 3 ;
                if ( moy < 0 ) moy = 0 ;
                if ( moy > 255 ) moy = 255 ;

#if SOBELF_DEBUG
                printf( "[DEBUG] Transparency color image %d (%d,%d,%d) -> (%d,%d,%d)\n",
                        i,
                        image->g->SColorMap->Colors[ tr_color ].Red,
                        image->g->SColorMap->Colors[ tr_color ].Green,
                        image->g->SColorMap->Colors[ tr_color ].Blue,
                        moy, moy, moy ) ;
#endif

                for ( k = 0 ; k < n_colors ; k++ )
                {
                    if ( 
                            moy == colormap[k].Red
                            &&
                            moy == colormap[k].Green
                            &&
                            moy == colormap[k].Blue
                       )
                    {
                        found = k ;
                    }
                }
                if ( found == -1  ) 
                {
                    if ( n_colors >= 256 ) 
                    {
                        fprintf( stderr, 
                                "Error: Found too many colors inside the image\n"
                               ) ;
                        return 0 ;
                    }

#if SOBELF_DEBUG
                    printf( "[DEBUG]\tNew color %d\n",
                            n_colors ) ;
#endif

                    colormap[n_colors].Red = moy ;
                    colormap[n_colors].Green = moy ;
                    colormap[n_colors].Blue = moy ;


                    image->g->ExtensionBlocks[j].Bytes[3] = n_colors ;

                    n_colors++ ;
                } else
                {
#if SOBELF_DEBUG
                    printf( "[DEBUG]\tFound existing color %d\n",
                            found ) ;
#endif
                    image->g->ExtensionBlocks[j].Bytes[3] = found ;
                }
            }
        }
    }









    //////// Possibility to parallelize over images ////////

    for ( i = 0 ; i < image->n_images ; i++ )
    {
        for ( j = 0 ; j < image->g->SavedImages[i].ExtensionBlockCount ; j++ )
        {
            int f ;

            f = image->g->SavedImages[i].ExtensionBlocks[j].Function ;
            if ( f == GRAPHICS_EXT_FUNC_CODE )
            {
                int tr_color = image->g->SavedImages[i].ExtensionBlocks[j].Bytes[3] ;

                if ( tr_color >= 0 &&
                        tr_color < 255 )
                {

                    int found = -1 ;

                    moy = 
                        (
                         image->g->SColorMap->Colors[ tr_color ].Red
                         +
                         image->g->SColorMap->Colors[ tr_color ].Green
                         +
                         image->g->SColorMap->Colors[ tr_color ].Blue
                        ) / 3 ;
                    if ( moy < 0 ) moy = 0 ;
                    if ( moy > 255 ) moy = 255 ;

#if SOBELF_DEBUG
                    printf( "[DEBUG] Transparency color image %d (%d,%d,%d) -> (%d,%d,%d)\n",
                            i,
                            image->g->SColorMap->Colors[ tr_color ].Red,
                            image->g->SColorMap->Colors[ tr_color ].Green,
                            image->g->SColorMap->Colors[ tr_color ].Blue,
                            moy, moy, moy ) ;
#endif

                    for ( k = 0 ; k < n_colors ; k++ )
                    {
                        if ( 
                                moy == colormap[k].Red
                                &&
                                moy == colormap[k].Green
                                &&
                                moy == colormap[k].Blue
                           )
                        {
                            found = k ;
                        }
                    }
                    if ( found == -1  ) 
                    {
                        if ( n_colors >= 256 ) 
                        {
                            fprintf( stderr, 
                                    "Error: Found too many colors inside the image\n"
                                   ) ;
                            return 0 ;
                        }

#if SOBELF_DEBUG
                        printf( "[DEBUG]\tNew color %d\n",
                                n_colors ) ;
#endif

                        colormap[n_colors].Red = moy ;
                        colormap[n_colors].Green = moy ;
                        colormap[n_colors].Blue = moy ;


                        image->g->SavedImages[i].ExtensionBlocks[j].Bytes[3] = n_colors ;

                        n_colors++ ;
                    } else
                    {
#if SOBELF_DEBUG
                        printf( "[DEBUG]\tFound existing color %d\n",
                                found ) ;
#endif
                        image->g->SavedImages[i].ExtensionBlocks[j].Bytes[3] = found ;
                    }
                }
            }
        }
    }

#if SOBELF_DEBUG
    printf( "[DEBUG] Number of colors after background and transparency: %d\n",
            n_colors ) ;
#endif

    p = image->p ;







    
    /* Find the number of colors inside the image */
    for ( i = 0 ; i < image->n_images ; i++ )
    {

#if SOBELF_DEBUG
        printf( "OUTPUT: Processing image %d (total of %d images) -> %d x %d\n",
                i, image->n_images, image->width[i], image->height[i] ) ;
#endif

        for ( j = 0 ; j < image->width[i] * image->height[i] ; j++ ) 
        {
            int found = 0 ;
            for ( k = 0 ; k < n_colors ; k++ )
            {
                if ( p[i][j].r == colormap[k].Red &&
                        p[i][j].g == colormap[k].Green &&
                        p[i][j].b == colormap[k].Blue )
                {
                    found = 1 ;
                }
            }

            if ( found == 0 ) 
            {
                if ( n_colors >= 256 ) 
                {
                    fprintf( stderr, 
                            "Error: Found too many colors inside the image\n"
                           ) ;
                    return 0 ;
                }

#if SOBELF_DEBUG
                printf( "[DEBUG] Found new %d color (%d,%d,%d)\n",
                        n_colors, p[i][j].r, p[i][j].g, p[i][j].b ) ;
#endif

                colormap[n_colors].Red = p[i][j].r ;
                colormap[n_colors].Green = p[i][j].g ;
                colormap[n_colors].Blue = p[i][j].b ;
                n_colors++ ;
            }
        }
    }







#if SOBELF_DEBUG
    printf( "OUTPUT: found %d color(s)\n", n_colors ) ;
#endif


    /* Round up to a power of 2 */
    if ( n_colors != (1 << GifBitSize(n_colors) ) )
    {
        n_colors = (1 << GifBitSize(n_colors) ) ;
    }

#if SOBELF_DEBUG
    printf( "OUTPUT: Rounding up to %d color(s)\n", n_colors ) ;
#endif

    /* Change the color map inside the animated gif */
    ColorMapObject * cmo ;

    cmo = GifMakeMapObject( n_colors, colormap ) ;
    if ( cmo == NULL )
    {
        fprintf( stderr, "Error while creating a ColorMapObject w/ %d color(s)\n",
                n_colors ) ;
        return 0 ;
    }

    image->g->SColorMap = cmo ;

    /* Update the raster bits according to color map */
    for ( i = 0 ; i < image->n_images ; i++ )
    {
        for ( j = 0 ; j < image->width[i] * image->height[i] ; j++ ) 
        {
            int found_index = -1 ;
            for ( k = 0 ; k < n_colors ; k++ ) 
            {
                if ( p[i][j].r == image->g->SColorMap->Colors[k].Red &&
                        p[i][j].g == image->g->SColorMap->Colors[k].Green &&
                        p[i][j].b == image->g->SColorMap->Colors[k].Blue )
                {
                    found_index = k ;
                }
            }

            if ( found_index == -1 ) 
            {
                fprintf( stderr,
                        "Error: Unable to find a pixel in the color map\n" ) ;
                return 0 ;
            }

            image->g->SavedImages[i].RasterBits[j] = found_index ;
        }
    }


    /* Write the final image */
    if ( !output_modified_read_gif( filename, image->g ) ) { return 0 ; }

    return 1 ;
}








/* GPU-accelerated version of store_pixels with CUDA */


/* CUDA kernel for pixel-to-colormap matching */
__global__ void findPixelIndicesInColormap(
    unsigned char* d_pixels_r, 
    unsigned char* d_pixels_g, 
    unsigned char* d_pixels_b,
    unsigned char* d_colormap_r, 
    unsigned char* d_colormap_g, 
    unsigned char* d_colormap_b,
    int* d_result_indices,
    int n_pixels,
    int n_colors)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    if (idx < n_pixels) {
        unsigned char r = d_pixels_r[idx];
        unsigned char g = d_pixels_g[idx];
        unsigned char b = d_pixels_b[idx];
        
        int found_index = -1;
        
        // Find matching color in colormap - exact same logic as original
        for (int k = 0; k < n_colors; k++) {
            if (r == d_colormap_r[k] && 
                g == d_colormap_g[k] && 
                b == d_colormap_b[k]) {
                
                found_index = k;
                break;  // Critical: Stop at first match, just like original
            }
        }
        
        d_result_indices[idx] = found_index;
    }
}



/* This is the main function - we'll only accelerate the final colormap matching */
//// Does not produce the same output...////
int store_pixels_gpu(char* filename, animated_gif* image)
{
    int n_colors = 0;
    pixel** p;
    int i, j, k;
    GifColorType* colormap;
    
    /* Initialize the new set of colors */
    colormap = (GifColorType*)malloc(256 * sizeof(GifColorType));
    if (colormap == NULL) {
        fprintf(stderr, "Unable to allocate 256 colors\n");
        return 0;
    }

    /* Everything is white by default */
    for (i = 0; i < 256; i++) {
        colormap[i].Red = 255;
        colormap[i].Green = 255;
        colormap[i].Blue = 255;
    }

    /* Change the background color and store it */
    int moy;
    moy = (
            image->g->SColorMap->Colors[image->g->SBackGroundColor].Red +
            image->g->SColorMap->Colors[image->g->SBackGroundColor].Green +
            image->g->SColorMap->Colors[image->g->SBackGroundColor].Blue
          ) / 3;
    if (moy < 0) moy = 0;
    if (moy > 255) moy = 255;

#if SOBELF_DEBUG
    printf("[DEBUG] Background color (%d,%d,%d) -> (%d,%d,%d)\n",
            image->g->SColorMap->Colors[image->g->SBackGroundColor].Red,
            image->g->SColorMap->Colors[image->g->SBackGroundColor].Green,
            image->g->SColorMap->Colors[image->g->SBackGroundColor].Blue,
            moy, moy, moy);
#endif

    colormap[0].Red = moy;
    colormap[0].Green = moy;
    colormap[0].Blue = moy;

    image->g->SBackGroundColor = 0;

    n_colors++;

    /* Process extension blocks in main structure - KEEPING EXACTLY AS ORIGINAL */
    for (j = 0; j < image->g->ExtensionBlockCount; j++) {
        int f;

        f = image->g->ExtensionBlocks[j].Function;
        if (f == GRAPHICS_EXT_FUNC_CODE) {
            int tr_color = image->g->ExtensionBlocks[j].Bytes[3];

            if (tr_color >= 0 && tr_color < 255) {
                int found = -1;

                moy = (
                       image->g->SColorMap->Colors[tr_color].Red +
                       image->g->SColorMap->Colors[tr_color].Green +
                       image->g->SColorMap->Colors[tr_color].Blue
                      ) / 3;
                if (moy < 0) moy = 0;
                if (moy > 255) moy = 255;

#if SOBELF_DEBUG
                printf("[DEBUG] Transparency color image %d (%d,%d,%d) -> (%d,%d,%d)\n",
                        i,
                        image->g->SColorMap->Colors[tr_color].Red,
                        image->g->SColorMap->Colors[tr_color].Green,
                        image->g->SColorMap->Colors[tr_color].Blue,
                        moy, moy, moy);
#endif

                for (k = 0; k < n_colors; k++) {
                    if (moy == colormap[k].Red &&
                        moy == colormap[k].Green &&
                        moy == colormap[k].Blue) {
                        found = k;
                    }
                }
                
                if (found == -1) {
                    if (n_colors >= 256) {
                        fprintf(stderr, "Error: Found too many colors inside the image\n");
                        return 0;
                    }

#if SOBELF_DEBUG
                    printf("[DEBUG]\tNew color %d\n", n_colors);
#endif

                    colormap[n_colors].Red = moy;
                    colormap[n_colors].Green = moy;
                    colormap[n_colors].Blue = moy;

                    image->g->ExtensionBlocks[j].Bytes[3] = n_colors;

                    n_colors++;
                } else {
#if SOBELF_DEBUG
                    printf("[DEBUG]\tFound existing color %d\n", found);
#endif
                    image->g->ExtensionBlocks[j].Bytes[3] = found;
                }
            }
        }
    }

    /* Process saved images extension blocks - KEEPING EXACTLY AS ORIGINAL */
    for (i = 0; i < image->n_images; i++) {
        for (j = 0; j < image->g->SavedImages[i].ExtensionBlockCount; j++) {
            int f;

            f = image->g->SavedImages[i].ExtensionBlocks[j].Function;
            if (f == GRAPHICS_EXT_FUNC_CODE) {
                int tr_color = image->g->SavedImages[i].ExtensionBlocks[j].Bytes[3];

                if (tr_color >= 0 && tr_color < 255) {
                    int found = -1;

                    moy = (
                           image->g->SColorMap->Colors[tr_color].Red +
                           image->g->SColorMap->Colors[tr_color].Green +
                           image->g->SColorMap->Colors[tr_color].Blue
                          ) / 3;
                    if (moy < 0) moy = 0;
                    if (moy > 255) moy = 255;

#if SOBELF_DEBUG
                    printf("[DEBUG] Transparency color image %d (%d,%d,%d) -> (%d,%d,%d)\n",
                            i,
                            image->g->SColorMap->Colors[tr_color].Red,
                            image->g->SColorMap->Colors[tr_color].Green,
                            image->g->SColorMap->Colors[tr_color].Blue,
                            moy, moy, moy);
#endif

                    for (k = 0; k < n_colors; k++) {
                        if (moy == colormap[k].Red &&
                            moy == colormap[k].Green &&
                            moy == colormap[k].Blue) {
                            found = k;
                        }
                    }
                    
                    if (found == -1) {
                        if (n_colors >= 256) {
                            fprintf(stderr, "Error: Found too many colors inside the image\n");
                            return 0;
                        }

#if SOBELF_DEBUG
                        printf("[DEBUG]\tNew color %d\n", n_colors);
#endif

                        colormap[n_colors].Red = moy;
                        colormap[n_colors].Green = moy;
                        colormap[n_colors].Blue = moy;

                        image->g->SavedImages[i].ExtensionBlocks[j].Bytes[3] = n_colors;

                        n_colors++;
                    } else {
#if SOBELF_DEBUG
                        printf("[DEBUG]\tFound existing color %d\n", found);
#endif
                        image->g->SavedImages[i].ExtensionBlocks[j].Bytes[3] = found;
                    }
                }
            }
        }
    }

#if SOBELF_DEBUG
    printf("[DEBUG] Number of colors after background and transparency: %d\n", n_colors);
#endif

    p = image->p;
    
    /* Find the number of colors inside the image - KEEPING EXACTLY AS ORIGINAL */
    for (i = 0; i < image->n_images; i++) {
#if SOBELF_DEBUG
        printf("OUTPUT: Processing image %d (total of %d images) -> %d x %d\n",
                i, image->n_images, image->width[i], image->height[i]);
#endif

        for (j = 0; j < image->width[i] * image->height[i]; j++) {
            int found = 0;
            for (k = 0; k < n_colors; k++) {
                if (p[i][j].r == colormap[k].Red &&
                    p[i][j].g == colormap[k].Green &&
                    p[i][j].b == colormap[k].Blue) {
                    found = 1;
                    break;  // Important: stop at first match
                }
            }

            if (found == 0) {
                if (n_colors >= 256) {
                    fprintf(stderr, "Error: Found too many colors inside the image\n");
                    return 0;
                }

#if SOBELF_DEBUG
                printf("[DEBUG] Found new %d color (%d,%d,%d)\n",
                        n_colors, p[i][j].r, p[i][j].g, p[i][j].b);
#endif

                colormap[n_colors].Red = p[i][j].r;
                colormap[n_colors].Green = p[i][j].g;
                colormap[n_colors].Blue = p[i][j].b;
                n_colors++;
            }
        }
    }

#if SOBELF_DEBUG
    printf("OUTPUT: found %d color(s)\n", n_colors);
#endif

    /* Round up to a power of 2 */
    if (n_colors != (1 << GifBitSize(n_colors))) {
        n_colors = (1 << GifBitSize(n_colors));
    }

#if SOBELF_DEBUG
    printf("OUTPUT: Rounding up to %d color(s)\n", n_colors);
#endif

    /* Change the color map inside the animated gif */
    ColorMapObject* cmo;
    cmo = GifMakeMapObject(n_colors, colormap);
    if (cmo == NULL) {
        fprintf(stderr, "Error while creating a ColorMapObject w/ %d color(s)\n", n_colors);
        return 0;
    }

    image->g->SColorMap = cmo;

    /* This is the only part we'll accelerate with CUDA: 
       Update the raster bits according to color map */
    
    // Check if CUDA is available
    int deviceCount = 0;
    cudaError_t cudaStatus = cudaGetDeviceCount(&deviceCount);
    if (cudaStatus != cudaSuccess || deviceCount == 0) {
        // Fallback to CPU implementation if CUDA is not available
        printf("CUDA acceleration not available, using CPU fallback\n");
        
        // Original CPU implementation
        for (i = 0; i < image->n_images; i++) {
            for (j = 0; j < image->width[i] * image->height[i]; j++) {
                int found_index = -1;
                for (k = 0; k < n_colors; k++) {
                    if (p[i][j].r == image->g->SColorMap->Colors[k].Red &&
                        p[i][j].g == image->g->SColorMap->Colors[k].Green &&
                        p[i][j].b == image->g->SColorMap->Colors[k].Blue) {
                        found_index = k;
                        break;  // Stop at first match
                    }
                }

                if (found_index == -1) {
                    fprintf(stderr, "Error: Unable to find a pixel in the color map\n");
                    return 0;
                }

                image->g->SavedImages[i].RasterBits[j] = found_index;
            }
        }
    } else {
        // CUDA implementation
        // Allocate and copy colormap to GPU memory
        unsigned char *d_colormap_r, *d_colormap_g, *d_colormap_b;
        
        cudaMalloc((void**)&d_colormap_r, n_colors * sizeof(unsigned char));
        cudaMalloc((void**)&d_colormap_g, n_colors * sizeof(unsigned char));
        cudaMalloc((void**)&d_colormap_b, n_colors * sizeof(unsigned char));
        
        // Prepare host colormap arrays
        unsigned char *h_colormap_r = (unsigned char*)malloc(n_colors * sizeof(unsigned char));
        unsigned char *h_colormap_g = (unsigned char*)malloc(n_colors * sizeof(unsigned char));
        unsigned char *h_colormap_b = (unsigned char*)malloc(n_colors * sizeof(unsigned char));
        
        for (k = 0; k < n_colors; k++) {
            h_colormap_r[k] = image->g->SColorMap->Colors[k].Red;
            h_colormap_g[k] = image->g->SColorMap->Colors[k].Green;
            h_colormap_b[k] = image->g->SColorMap->Colors[k].Blue;
        }
        
        cudaMemcpy(d_colormap_r, h_colormap_r, n_colors * sizeof(unsigned char), cudaMemcpyHostToDevice);
        cudaMemcpy(d_colormap_g, h_colormap_g, n_colors * sizeof(unsigned char), cudaMemcpyHostToDevice);
        cudaMemcpy(d_colormap_b, h_colormap_b, n_colors * sizeof(unsigned char), cudaMemcpyHostToDevice);
        
        // Process each image separately
        for (i = 0; i < image->n_images; i++) {
            int n_pixels = image->width[i] * image->height[i];
            
            // Skip small images - not worth GPU overhead
            if (n_pixels < 1000) {
                // Use CPU for small images
                for (j = 0; j < n_pixels; j++) {
                    int found_index = -1;
                    for (k = 0; k < n_colors; k++) {
                        if (p[i][j].r == image->g->SColorMap->Colors[k].Red &&
                            p[i][j].g == image->g->SColorMap->Colors[k].Green &&
                            p[i][j].b == image->g->SColorMap->Colors[k].Blue) {
                            found_index = k;
                            break;
                        }
                    }

                    if (found_index == -1) {
                        fprintf(stderr, "Error: Unable to find a pixel in the color map\n");
                        // Clean up
                        cudaFree(d_colormap_r);
                        cudaFree(d_colormap_g);
                        cudaFree(d_colormap_b);
                        free(h_colormap_r);
                        free(h_colormap_g);
                        free(h_colormap_b);
                        return 0;
                    }

                    image->g->SavedImages[i].RasterBits[j] = found_index;
                }
                continue;  // Skip to next image
            }
            
            // Allocate device memory for pixels and results
            unsigned char *d_pixels_r, *d_pixels_g, *d_pixels_b;
            int *d_result_indices;
            
            cudaMalloc((void**)&d_pixels_r, n_pixels * sizeof(unsigned char));
            cudaMalloc((void**)&d_pixels_g, n_pixels * sizeof(unsigned char));
            cudaMalloc((void**)&d_pixels_b, n_pixels * sizeof(unsigned char));
            cudaMalloc((void**)&d_result_indices, n_pixels * sizeof(int));
            
            // Prepare host pixel arrays
            unsigned char *h_pixels_r = (unsigned char*)malloc(n_pixels * sizeof(unsigned char));
            unsigned char *h_pixels_g = (unsigned char*)malloc(n_pixels * sizeof(unsigned char));
            unsigned char *h_pixels_b = (unsigned char*)malloc(n_pixels * sizeof(unsigned char));
            int *h_result_indices = (int*)malloc(n_pixels * sizeof(int));
            
            // Extract pixel data
            for (j = 0; j < n_pixels; j++) {
                h_pixels_r[j] = p[i][j].r;
                h_pixels_g[j] = p[i][j].g;
                h_pixels_b[j] = p[i][j].b;
            }
            
            // Copy pixel data to device
            cudaMemcpy(d_pixels_r, h_pixels_r, n_pixels * sizeof(unsigned char), cudaMemcpyHostToDevice);
            cudaMemcpy(d_pixels_g, h_pixels_g, n_pixels * sizeof(unsigned char), cudaMemcpyHostToDevice);
            cudaMemcpy(d_pixels_b, h_pixels_b, n_pixels * sizeof(unsigned char), cudaMemcpyHostToDevice);
            
            // Initialize result indices to -1
            cudaMemset(d_result_indices, -1, n_pixels * sizeof(int));
            
            // Launch kernel
            int blockSize = 256;
            int gridSize = (n_pixels + blockSize - 1) / blockSize;
            
            findPixelIndicesInColormap<<<gridSize, blockSize>>>(
                d_pixels_r, d_pixels_g, d_pixels_b,
                d_colormap_r, d_colormap_g, d_colormap_b,
                d_result_indices, n_pixels, n_colors
            );
            
            // Check for errors
            cudaDeviceSynchronize();
            cudaStatus = cudaGetLastError();
            if (cudaStatus != cudaSuccess) {
                fprintf(stderr, "CUDA kernel error: %s\n", cudaGetErrorString(cudaStatus));
                // Fall back to CPU implementation for this image
                for (j = 0; j < n_pixels; j++) {
                    int found_index = -1;
                    for (k = 0; k < n_colors; k++) {
                        if (p[i][j].r == image->g->SColorMap->Colors[k].Red &&
                            p[i][j].g == image->g->SColorMap->Colors[k].Green &&
                            p[i][j].b == image->g->SColorMap->Colors[k].Blue) {
                            found_index = k;
                            break;
                        }
                    }

                    if (found_index == -1) {
                        fprintf(stderr, "Error: Unable to find a pixel in the color map\n");
                        // Clean up
                        cudaFree(d_pixels_r);
                        cudaFree(d_pixels_g);
                        cudaFree(d_pixels_b);
                        cudaFree(d_result_indices);
                        free(h_pixels_r);
                        free(h_pixels_g);
                        free(h_pixels_b);
                        free(h_result_indices);
                        cudaFree(d_colormap_r);
                        cudaFree(d_colormap_g);
                        cudaFree(d_colormap_b);
                        free(h_colormap_r);
                        free(h_colormap_g);
                        free(h_colormap_b);
                        return 0;
                    }

                    image->g->SavedImages[i].RasterBits[j] = found_index;
                }
            } else {
                // Copy results back to host
                cudaMemcpy(h_result_indices, d_result_indices, n_pixels * sizeof(int), cudaMemcpyDeviceToHost);
                
                // Apply results
                for (j = 0; j < n_pixels; j++) {
                    if (h_result_indices[j] == -1) {
                        fprintf(stderr, "Error: CUDA kernel could not find a pixel in the color map\n");
                        // Clean up
                        cudaFree(d_pixels_r);
                        cudaFree(d_pixels_g);
                        cudaFree(d_pixels_b);
                        cudaFree(d_result_indices);
                        free(h_pixels_r);
                        free(h_pixels_g);
                        free(h_pixels_b);
                        free(h_result_indices);
                        cudaFree(d_colormap_r);
                        cudaFree(d_colormap_g);
                        cudaFree(d_colormap_b);
                        free(h_colormap_r);
                        free(h_colormap_g);
                        free(h_colormap_b);
                        return 0;
                    }
                    
                    image->g->SavedImages[i].RasterBits[j] = h_result_indices[j];
                }
            }
            
            // Free resources for this image
            cudaFree(d_pixels_r);
            cudaFree(d_pixels_g);
            cudaFree(d_pixels_b);
            cudaFree(d_result_indices);
            free(h_pixels_r);
            free(h_pixels_g);
            free(h_pixels_b);
            free(h_result_indices);
        }
        
        // Free colormap resources
        cudaFree(d_colormap_r);
        cudaFree(d_colormap_g);
        cudaFree(d_colormap_b);
        free(h_colormap_r);
        free(h_colormap_g);
        free(h_colormap_b);
    }
    
    /* Write the final image */
    if (!output_modified_read_gif(filename, image->g)) {
        return 0;
    }
    
    return 1;
}











__global__ void gray_filter_kernel(pixel *d_pixels, int width, int height, int total_pixels) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x ;

    //no out of bounds
    if (idx < total_pixels) {
        int moy = (d_pixels[idx].r + d_pixels[idx].g + d_pixels[idx].b)/3 ;

        // clamp
        if (moy < 0) moy = 0;
        if (moy > 255) moy = 255 ;

        // update pixel
        d_pixels[idx].r = moy ;
        d_pixels[idx].g = moy ;
        d_pixels[idx].b = moy ;
    }
}


void apply_gray_filter_gpu(animated_gif *image){
    pixel **p = image->p ;

    //process each image
    for (int i = 0; i< image->n_images; i++) {
        int width = image->width[i];
        int height = image->height[i];
        int total_pixels = width * height;

        // mem on runtime
        pixel *d_pixels;
        cudaMalloc(&d_pixels, total_pixels * sizeof(pixel));

        // transfer data
        cudaMemcpy(d_pixels, p[i], total_pixels * sizeof(pixel), cudaMemcpyHostToDevice);

        // setup CUDA kernel
        int threadsPerBlock = 256;
        int blocksPerGrid = (total_pixels + threadsPerBlock - 1) / threadsPerBlock; // technique to round up 

        // call kernel
        gray_filter_kernel<<<blocksPerGrid, threadsPerBlock>>>(d_pixels, width, height, total_pixels);

        // wait for GPU to finish
        cudaDeviceSynchronize(); // ensures all GPU operations are done

        // transfer back data
        cudaMemcpy(p[i], d_pixels, total_pixels * sizeof(pixel), cudaMemcpyDeviceToHost);

        // free GPU mem
        cudaFree(d_pixels);

    }
}




void apply_gray_filter_gpu_batch(animated_gif *image) {
    pixel **p = image->p;
    
    // Calculate total size for all images
    int total_images = image->n_images;
    size_t total_bytes = 0;
    for (int i = 0; i < total_images; i++) {
        total_bytes += image->width[i] * image->height[i] * sizeof(pixel);
    }
    
    // Create a single buffer for all images
    char *h_buffer = (char *)malloc(total_bytes);
    if (!h_buffer) {
        fprintf(stderr, "Failed to allocate host memory\n");
        return;
    }
    
    // Create offsets for each image in the buffer
    size_t *offsets = (size_t *)malloc(total_images * sizeof(size_t));
    size_t *sizes = (size_t *)malloc(total_images * sizeof(size_t));
    size_t current_offset = 0;
    
    for (int i = 0; i < total_images; i++) {
        offsets[i] = current_offset;
        sizes[i] = image->width[i] * image->height[i] * sizeof(pixel);
        memcpy(h_buffer + current_offset, p[i], sizes[i]);
        current_offset += sizes[i];
    }
    
    // Allocate GPU memory and copy all data at once
    char *d_buffer;
    cudaMalloc(&d_buffer, total_bytes);
    cudaMemcpy(d_buffer, h_buffer, total_bytes, cudaMemcpyHostToDevice);
    
    // Launch kernel for each image
    for (int i = 0; i < total_images; i++) {
        int total_pixels = image->width[i] * image->height[i];
        int threadsPerBlock = 256;
        int blocksPerGrid = (total_pixels + threadsPerBlock - 1) / threadsPerBlock;
        
        gray_filter_kernel<<<blocksPerGrid, threadsPerBlock>>>(
            (pixel *)(d_buffer + offsets[i]), 
            image->width[i], 
            image->height[i], 
            total_pixels
        );
    }
    
    // Wait for all operations to complete
    cudaDeviceSynchronize();
    
    // Copy results back
    cudaMemcpy(h_buffer, d_buffer, total_bytes, cudaMemcpyDeviceToHost);
    
    // Copy results back to original structure
    for (int i = 0; i < total_images; i++) {
        memcpy(p[i], h_buffer + offsets[i], sizes[i]);
    }
    
    // Free resources
    cudaFree(d_buffer);
    free(h_buffer);
    free(offsets);
    free(sizes);
}







///////////// Possibility to parallelize this function ///////////////////
void
apply_gray_filter( animated_gif * image )
{
    int i, j ;
    pixel ** p ;

    p = image->p ;

    for ( i = 0 ; i < image->n_images ; i++ )
    {
        for ( j = 0 ; j < image->width[i] * image->height[i] ; j++ )
        {
            int moy ;

            moy = (p[i][j].r + p[i][j].g + p[i][j].b)/3 ;
            if ( moy < 0 ) moy = 0 ;
            if ( moy > 255 ) moy = 255 ;

            p[i][j].r = moy ;
            p[i][j].g = moy ;
            p[i][j].b = moy ;
        }
    }
}

#define CONV(l,c,nb_c) \
    (l)*(nb_c)+(c)











/////////// Possibility to parallelize this function ///////////////////
void apply_gray_line( animated_gif * image ) 
{
    int i, j, k ;
    pixel ** p ;

    p = image->p ;

    for ( i = 0 ; i < image->n_images ; i++ )
    {
        for ( j = 0 ; j < 10 ; j++ )
        {
            for ( k = image->width[i]/2 ; k < image->width[i] ; k++ )
            {
            p[i][CONV(j,k,image->width[i])].r = 0 ;
            p[i][CONV(j,k,image->width[i])].g = 0 ;
            p[i][CONV(j,k,image->width[i])].b = 0 ;
            }
        }
    }
}




































// CUDA kernel for blurring the top and bottom parts of the image
__global__ void blur_kernel(pixel* d_pixels, pixel* d_new_pixels, int width, int height, 
    int size, int region_start, int region_end) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    // Check if this thread is within the image boundaries and the specified region
    if (col >= size && col < width - size && row >= region_start && row < region_end) {
        int t_r = 0;
        int t_g = 0;
        int t_b = 0;

        // Apply the blur stencil
        for (int stencil_j = -size; stencil_j <= size; stencil_j++) {
            for (int stencil_k = -size; stencil_k <= size; stencil_k++) {
            int idx = CONV(row + stencil_j, col + stencil_k, width);
            t_r += d_pixels[idx].r;
            t_g += d_pixels[idx].g;
            t_b += d_pixels[idx].b;
            }
        }

        // Calculate average and store in new pixels
        int total_pixels = (2 * size + 1) * (2 * size + 1);
        d_new_pixels[CONV(row, col, width)].r = t_r / total_pixels;
        d_new_pixels[CONV(row, col, width)].g = t_g / total_pixels;
        d_new_pixels[CONV(row, col, width)].b = t_b / total_pixels;
    }
}

// CUDA kernel for copying the original pixel values (for non-blurred regions)
__global__ void copy_kernel(pixel* d_pixels, pixel* d_new_pixels, int width, int height, 
    int region_start, int region_end) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    // Check if this thread is within the image boundaries and the specified region
    if (col >= 0 && col < width && row >= region_start && row < region_end) {
        int idx = CONV(row, col, width);
        d_new_pixels[idx].r = d_pixels[idx].r;
        d_new_pixels[idx].g = d_pixels[idx].g;
        d_new_pixels[idx].b = d_pixels[idx].b;
    }
}

// CUDA kernel to check if we need more iterations
__global__ void check_threshold_kernel(pixel* d_pixels, pixel* d_new_pixels, int width, int height, 
               int threshold, int* d_end) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    // Check if this thread is within the valid image boundaries
    if (col >= 1 && col < width - 1 && row >= 1 && row < height - 1) {
        int idx = CONV(row, col, width);

        float diff_r = d_new_pixels[idx].r - d_pixels[idx].r;
        float diff_g = d_new_pixels[idx].g - d_pixels[idx].g;
        float diff_b = d_new_pixels[idx].b - d_pixels[idx].b;

        if (diff_r > threshold || -diff_r > threshold ||
            diff_g > threshold || -diff_g > threshold ||
            diff_b > threshold || -diff_b > threshold) {
            *d_end = 0;
        }

        // Also update the original pixels with new values
        d_pixels[idx].r = d_new_pixels[idx].r;
        d_pixels[idx].g = d_new_pixels[idx].g;
        d_pixels[idx].b = d_new_pixels[idx].b;
    }
}





// New multi-image implementation
void apply_blur_filter_multi_gpu(animated_gif* image, int size, int threshold) {
    int n_images = image->n_images;
    pixel** p = image->p;
    
    // Create CUDA streams - one per image for parallel processing
    cudaStream_t* streams = (cudaStream_t*)malloc(n_images * sizeof(cudaStream_t));
    for (int i = 0; i < n_images; i++) {
        cudaStreamCreate(&streams[i]);
    }
    
    // Allocate host arrays to track state for each image
    int* n_iters = (int*)calloc(n_images, sizeof(int));
    int* h_ends = (int*)malloc(n_images * sizeof(int));
    
    // Arrays to store device pointers for each image
    pixel** d_pixels_array = (pixel**)malloc(n_images * sizeof(pixel*));
    pixel** d_new_pixels_array = (pixel**)malloc(n_images * sizeof(pixel*));
    int** d_end_array = (int**)malloc(n_images * sizeof(int*));
    
    // Allocate memory and copy data for each image
    for (int i = 0; i < n_images; i++) {
        int width = image->width[i];
        int height = image->height[i];
        int total_pixels = width * height;
        
        // Allocate device memory for this image
        cudaMalloc(&d_pixels_array[i], total_pixels * sizeof(pixel));
        cudaMalloc(&d_new_pixels_array[i], total_pixels * sizeof(pixel));
        cudaMalloc(&d_end_array[i], sizeof(int));
        
        // Copy image data to device using this image's stream
        cudaMemcpyAsync(d_pixels_array[i], p[i], total_pixels * sizeof(pixel), 
                       cudaMemcpyHostToDevice, streams[i]);
    }
    
    // Wait for all initial copies to complete
    cudaDeviceSynchronize();
    
    // Process all images in parallel
    bool all_images_done = false;
    
    while (!all_images_done) {
        all_images_done = true;
        
        // Process each image in its own stream
        for (int i = 0; i < n_images; i++) {
            int width = image->width[i];
            int height = image->height[i];
            
            // Skip images that are done
            if (threshold > 0 && h_ends[i] == 1) {
                continue;
            }
            
            // This image is still being processed
            all_images_done = false;
            n_iters[i]++;
            
            // Set the end flag to 1 at the beginning of iteration
            h_ends[i] = 1;
            cudaMemcpyAsync(d_end_array[i], &h_ends[i], sizeof(int), 
                           cudaMemcpyHostToDevice, streams[i]);
            
            // Define the regions for processing
            int top_start = size;
            int top_end = height / 10 - size;
            int middle_start = height / 10 - size;
            int middle_end = height * 0.9 + size;
            int bottom_start = height * 0.9 + size;
            int bottom_end = height - size;
            
            // Define the grid and block dimensions
            dim3 threadsPerBlock(16, 16);
            dim3 blocksPerGrid((width + threadsPerBlock.x - 1) / threadsPerBlock.x,
                               (height + threadsPerBlock.y - 1) / threadsPerBlock.y);
            
            // Initialize new_pixels with edge values
            cudaMemcpyAsync(d_new_pixels_array[i], d_pixels_array[i], 
                           width * height * sizeof(pixel), 
                           cudaMemcpyDeviceToDevice, streams[i]);
            
            // Apply blur to the top region
            blur_kernel<<<blocksPerGrid, threadsPerBlock, 0, streams[i]>>>(
                d_pixels_array[i], d_new_pixels_array[i], width, height, 
                size, top_start, top_end);
            
            // Copy the middle part (no blur)
            copy_kernel<<<blocksPerGrid, threadsPerBlock, 0, streams[i]>>>(
                d_pixels_array[i], d_new_pixels_array[i], width, height, 
                middle_start, middle_end);
            
            // Apply blur to the bottom region
            blur_kernel<<<blocksPerGrid, threadsPerBlock, 0, streams[i]>>>(
                d_pixels_array[i], d_new_pixels_array[i], width, height, 
                size, bottom_start, bottom_end);
            
            // Check threshold and update pixels
            check_threshold_kernel<<<blocksPerGrid, threadsPerBlock, 0, streams[i]>>>(
                d_pixels_array[i], d_new_pixels_array[i], width, height, 
                threshold, d_end_array[i]);
            
            // Get the end flag back to host
            cudaMemcpyAsync(&h_ends[i], d_end_array[i], sizeof(int), 
                           cudaMemcpyDeviceToHost, streams[i]);
        }
        
        // Synchronize all streams before checking end conditions
        cudaDeviceSynchronize();
    }
    
    // Copy results back to host
    for (int i = 0; i < n_images; i++) {
        int total_pixels = image->width[i] * image->height[i];
        
        cudaMemcpyAsync(p[i], d_pixels_array[i], total_pixels * sizeof(pixel), 
                       cudaMemcpyDeviceToHost, streams[i]);
    }
    
    // Wait for all copies to complete
    cudaDeviceSynchronize();
    
    // Debug output
#if SOBELF_DEBUG
    for (int i = 0; i < n_images; i++) {
        printf("BLUR: number of iterations for image %d: %d\n", i, n_iters[i]);
    }
#endif
    
    // Clean up
    for (int i = 0; i < n_images; i++) {
        cudaFree(d_pixels_array[i]);
        cudaFree(d_new_pixels_array[i]);
        cudaFree(d_end_array[i]);
        cudaStreamDestroy(streams[i]);
    }
    
    free(streams);
    free(n_iters);
    free(h_ends);
    free(d_pixels_array);
    free(d_new_pixels_array);
    free(d_end_array);
}
























// Sobel filter kernel - processes one pixel per thread
__global__ void sobel_filter_kernel(pixel* input, pixel* output, int width, int height) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    
    // Only process interior pixels (exclude borders)
    if (col >= 1 && col < width - 1 && row >= 1 && row < height - 1) {
        // Get neighboring pixel values (blue channel only)
        int pixel_blue_no = input[CONV(row-1, col-1, width)].b;
        int pixel_blue_n  = input[CONV(row-1, col  , width)].b;
        int pixel_blue_ne = input[CONV(row-1, col+1, width)].b;
        int pixel_blue_so = input[CONV(row+1, col-1, width)].b;
        int pixel_blue_s  = input[CONV(row+1, col  , width)].b;
        int pixel_blue_se = input[CONV(row+1, col+1, width)].b;
        int pixel_blue_o  = input[CONV(row  , col-1, width)].b;
        int pixel_blue    = input[CONV(row  , col  , width)].b;
        int pixel_blue_e  = input[CONV(row  , col+1, width)].b;
        
        // Calculate Sobel operators
        float deltaX_blue = -pixel_blue_no + pixel_blue_ne - 2*pixel_blue_o + 2*pixel_blue_e - pixel_blue_so + pixel_blue_se;
        float deltaY_blue = pixel_blue_se + 2*pixel_blue_s + pixel_blue_so - pixel_blue_ne - 2*pixel_blue_n - pixel_blue_no;
        
        // Calculate magnitude and normalize
        float val_blue = sqrt(deltaX_blue * deltaX_blue + deltaY_blue * deltaY_blue) / 4.0f;
        
        // Apply threshold
        if (val_blue > 50.0f) {
            output[CONV(row, col, width)].r = 255;
            output[CONV(row, col, width)].g = 255;
            output[CONV(row, col, width)].b = 255;
        } else {
            output[CONV(row, col, width)].r = 0;
            output[CONV(row, col, width)].g = 0;
            output[CONV(row, col, width)].b = 0;
        }
    }
}

// Kernel to copy results back to original image
__global__ void copy_result_kernel(pixel* sobel, pixel* output, int width, int height) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (col >= 1 && col < width - 1 && row >= 1 && row < height - 1) {
        int idx = CONV(row, col, width);
        output[idx].r = sobel[idx].r;
        output[idx].g = sobel[idx].g;
        output[idx].b = sobel[idx].b;
    }
}

void apply_sobel_filter_gpu(animated_gif* image) {
    pixel** p = image->p;
    int n_images = image->n_images;
    
    // Create CUDA streams - one per image for parallel processing
    cudaStream_t* streams = (cudaStream_t*)malloc(n_images * sizeof(cudaStream_t));
    for (int i = 0; i < n_images; i++) {
        cudaStreamCreate(&streams[i]);
    }
    
    // Process all images in parallel
    for (int i = 0; i < n_images; i++) {
        int width = image->width[i];
        int height = image->height[i];
        int total_pixels = width * height;
        
        // Allocate device memory
        pixel* d_input;
        pixel* d_sobel;
        cudaMalloc(&d_input, total_pixels * sizeof(pixel));
        cudaMalloc(&d_sobel, total_pixels * sizeof(pixel));
        
        // Initialize d_sobel to zeros (for border pixels)
        cudaMemset(d_sobel, 0, total_pixels * sizeof(pixel));
        
        // Copy image data to device
        cudaMemcpyAsync(d_input, p[i], total_pixels * sizeof(pixel), 
                       cudaMemcpyHostToDevice, streams[i]);
        
        // Set up grid and block dimensions
        dim3 threadsPerBlock(16, 16);
        dim3 numBlocks((width + threadsPerBlock.x - 1) / threadsPerBlock.x,
                       (height + threadsPerBlock.y - 1) / threadsPerBlock.y);
        
        // Launch Sobel filter kernel
        sobel_filter_kernel<<<numBlocks, threadsPerBlock, 0, streams[i]>>>(
            d_input, d_sobel, width, height);
        
        // Copy results back to input
        copy_result_kernel<<<numBlocks, threadsPerBlock, 0, streams[i]>>>(
            d_sobel, d_input, width, height);
        
        // Copy results back to host
        cudaMemcpyAsync(p[i], d_input, total_pixels * sizeof(pixel), 
                       cudaMemcpyDeviceToHost, streams[i]);
        
        // Free device memory (asynchronously using events for better performance)
        cudaEvent_t event;
        cudaEventCreate(&event);
        cudaEventRecord(event, streams[i]);
        
        // Create a callback to free memory when operations complete
        cudaStreamAddCallback(streams[i], [](cudaStream_t stream, cudaError_t status, void* userData) {
            pixel** devPtrs = (pixel**)userData;
            cudaFree(devPtrs[0]); // d_input
            cudaFree(devPtrs[1]); // d_sobel
            free(devPtrs);        // Free the container
        }, new pixel*[2]{d_input, d_sobel}, 0);
    }
    
    // Wait for all operations to complete
    cudaDeviceSynchronize();
    
    // Clean up streams
    for (int i = 0; i < n_images; i++) {
        cudaStreamDestroy(streams[i]);
    }
    free(streams);
}






















/*
 * Main entry point
 */
int main( int argc, char ** argv )
{
    char * input_filename ; 
    char * output_filename ;
    animated_gif * image ;
    struct timeval t1, t2;
    double import_duration, gray_duration, blur_duration, sobel_duration, filter_duration, export_duration;
    FILE *duration_file;

    /* Check command-line arguments */
    if ( argc < 3 )
    {
        fprintf( stderr, "Usage: %s input.gif output.gif \n", argv[0] ) ;
        return 1 ;
    }

    input_filename = argv[1] ;
    output_filename = argv[2] ;

    duration_file = fopen("durations_para_GPU.csv", "a");
    if (duration_file == NULL) {
        perror("Erreur lors de l'ouverture du fichier");
        return 1;
    }

    /* Check if the file is empty to write the header */
    fseek(duration_file, 0, SEEK_END);
    if (ftell(duration_file) == 0) {
        fprintf(duration_file, "Filename,Number Images,Number Pixels,Import Duration,Gray Filter Duration,Blur Filter Duration,Sobel Filter Duration,Export Duration\n");
    }
    fseek(duration_file, 0, SEEK_END);

    /* IMPORT Timer start */
    gettimeofday(&t1, NULL);

    /* Load file and store the pixels in array */
    image = load_pixels( input_filename ) ;
    if ( image == NULL ) { return 1 ; }

    /* IMPORT Timer stop */
    gettimeofday(&t2, NULL);

    import_duration = (t2.tv_sec -t1.tv_sec)+((t2.tv_usec-t1.tv_usec)/1e6);

#if PRINT_TIME
    printf( "GIF loaded from file %s with %d image(s) in %lf s\n", 
            input_filename, image->n_images, import_duration ) ;
#endif

    int nb_images = image->n_images;
    int nb_pixels = image->width[0] * image->height[0];





    /* FILTER Timer start */
    gettimeofday(&t1, NULL);

    /* Gray Filter Timer start */
    gettimeofday(&t1, NULL);
    apply_gray_filter( image ) ;
    gettimeofday(&t2, NULL);
    gray_duration = (t2.tv_sec -t1.tv_sec)+((t2.tv_usec-t1.tv_usec)/1e6);












#if PRINT_TIME
    printf( "Gray filter done in %lf s\n", gray_duration );
#endif






    /* Blur Filter Timer start */
    gettimeofday(&t1, NULL);
    apply_blur_filter_multi_gpu( image, 5, 20 ) ;
    gettimeofday(&t2, NULL);
    blur_duration = (t2.tv_sec -t1.tv_sec)+((t2.tv_usec-t1.tv_usec)/1e6);






#if PRINT_TIME
    printf( "Blur filter done in %lf s\n", blur_duration );
#endif






    /* Sobel Filter Timer start */
    gettimeofday(&t1, NULL);
    apply_sobel_filter_gpu( image ) ;
    gettimeofday(&t2, NULL);
    sobel_duration = (t2.tv_sec -t1.tv_sec)+((t2.tv_usec-t1.tv_usec)/1e6);





#if PRINT_TIME
    printf( "Sobel filter done in %lf s\n", sobel_duration );
#endif

    /* FILTER Timer stop */
    filter_duration = gray_duration + blur_duration + sobel_duration;
    printf( "Total filter time: %lf s\n", filter_duration );

    /* EXPORT Timer start */
    gettimeofday(&t1, NULL);

    /* Store file from array of pixels to GIF file */
    if ( !store_pixels( output_filename, image ) ) { return 1 ; }

    /* EXPORT Timer stop */
    gettimeofday(&t2, NULL);

    export_duration = (t2.tv_sec -t1.tv_sec)+((t2.tv_usec-t1.tv_usec)/1e6);

#if PRINT_TIME
    printf( "Export done in %lf s in file %s\n", export_duration, output_filename );
#endif

    /* Write durations to file */
    fprintf(duration_file, "%s, %d, %d, %lf,%lf,%lf,%lf,%lf\n", input_filename, nb_images, nb_pixels, import_duration, gray_duration, blur_duration, sobel_duration, export_duration);

    /* Close the file */
    fclose(duration_file);

    return 0 ;
}
