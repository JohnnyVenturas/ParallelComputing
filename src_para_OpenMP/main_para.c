/*
 * INF560
 *
 * Image Filtering Project
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

#include "gif_lib.h"

/* Set this macro to 1 to enable debugging information */
#define SOBELF_DEBUG 0

/* Set this macro to 1 to print the time taken by each step */
#define PRINT_TIME 0

#define NO_PARALLELIZATION 0
#define PARALLELIZE_IMAGES 1
#define PARALLELIZE_PIXELS 2

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
 load_pixels(char * filename) 
 {
     GifFileType * g;
     ColorMapObject * colmap;
     int error;
     int n_images;
     int * width;
     int * height;
     pixel ** p;
     int i;
     animated_gif * image;

 
     /* Open the GIF image (read mode) */
     g = DGifOpenFileName(filename, &error);
     if (g == NULL) 
     {
         fprintf(stderr, "Error DGifOpenFileName %s\n", filename);
         return NULL;
     }
 
     /* Read the GIF image */
     error = DGifSlurp(g);
     if (error != GIF_OK)
     {
         fprintf(stderr, 
                 "Error DGifSlurp: %d <%s>\n", error, GifErrorString(g->Error));
         return NULL;
     }
 
     /* Grab the number of images and the size of each image */
     n_images = g->ImageCount;
 
     width = (int *)malloc(n_images * sizeof(int));
     if (width == NULL)
     {
         fprintf(stderr, "Unable to allocate width of size %d\n", n_images);
         return NULL; // Fixed: return NULL instead of 0
     }
 
     height = (int *)malloc(n_images * sizeof(int));
     if (height == NULL)
     {
         fprintf(stderr, "Unable to allocate height of size %d\n", n_images);
         free(width); // Free previously allocated memory
         return NULL; // Fixed: return NULL instead of 0
     }
 
     /* Fill the width and height - keep this sequential, it's lightweight */
     for (i = 0; i < n_images; i++) 
     {
         width[i] = g->SavedImages[i].ImageDesc.Width;
         height[i] = g->SavedImages[i].ImageDesc.Height;
 
 #if SOBELF_DEBUG
         printf("Image %d: l:%d t:%d w:%d h:%d interlace:%d localCM:%p\n",
                 i, 
                 g->SavedImages[i].ImageDesc.Left,
                 g->SavedImages[i].ImageDesc.Top,
                 g->SavedImages[i].ImageDesc.Width,
                 g->SavedImages[i].ImageDesc.Height,
                 g->SavedImages[i].ImageDesc.Interlace,
                 g->SavedImages[i].ImageDesc.ColorMap
                 );
 #endif
     }
 
     /* Get the global colormap */
     colmap = g->SColorMap;
     if (colmap == NULL) 
     {
         fprintf(stderr, "Error global colormap is NULL\n");
         free(width);
         free(height);
         return NULL;
     }
 
 #if SOBELF_DEBUG
     printf("Global color map: count:%d bpp:%d sort:%d\n",
             g->SColorMap->ColorCount,
             g->SColorMap->BitsPerPixel,
             g->SColorMap->SortFlag
             );
 #endif


 
     /* Check for local colormaps before any parallel region */
     for (i = 0; i < n_images; i++)
     {
         if (g->SavedImages[i].ImageDesc.ColorMap)
         {
             fprintf(stderr, "Error: application does not support local colormap\n");
             free(width);
             free(height);
             return NULL;
         }
     }
 
     /* Allocate the array of pixels to be returned */
     p = (pixel **)malloc(n_images * sizeof(pixel *));
     if (p == NULL)
     {
         fprintf(stderr, "Unable to allocate array of %d images\n", n_images);
         free(width);
         free(height);
         return NULL;
     }
 
     /* Allocate memory for each image - keep sequential for proper error handling */
     for (i = 0; i < n_images; i++) 
     {
         p[i] = (pixel *)malloc(width[i] * height[i] * sizeof(pixel));
         if (p[i] == NULL)
         {
             fprintf(stderr, "Unable to allocate %d-th array of %d pixels\n",
                   i, width[i] * height[i]);
             
             /* Clean up already allocated memory */
             for (int j = 0; j < i; j++) {
                 free(p[j]);
             }
             free(p);
             free(width);
             free(height);
             return NULL;
         }
     }
     
     /* Fill pixels */
     /* Strategy depends on number of images and their sizes */
     if (n_images > 1) {
         /* For multiple images: parallelize at the image level */
         #pragma omp parallel for schedule(dynamic) 
         for (i = 0; i < n_images; i++)
         {
             int j;
             int w = width[i];
             int h = height[i];
             int pixel_count = w * h;
             
             /* Traverse the image and fill pixels */
             /* For large images, we can further parallelize the pixel processing */
             if (pixel_count > 100000) { /* Threshold for large images */
                 #pragma omp parallel for
                 for (j = 0; j < pixel_count; j++) 
                 {
                     int c = g->SavedImages[i].RasterBits[j];
                     p[i][j].r = colmap->Colors[c].Red;
                     p[i][j].g = colmap->Colors[c].Green;
                     p[i][j].b = colmap->Colors[c].Blue;
                 }
             } else {
                 /* For smaller images, process pixels sequentially */
                 for (j = 0; j < pixel_count; j++) 
                 {
                     int c = g->SavedImages[i].RasterBits[j];
                     p[i][j].r = colmap->Colors[c].Red;
                     p[i][j].g = colmap->Colors[c].Green;
                     p[i][j].b = colmap->Colors[c].Blue;
                 }
             }
         }
     } else {
         /* For a single image: parallelize at the pixel level if the image is large enough */
         int pixel_count = width[0] * height[0];
         
         #pragma omp parallel for if(pixel_count > 50000)
         for (int j = 0; j < pixel_count; j++) 
         {
             int c = g->SavedImages[0].RasterBits[j];
             p[0][j].r = colmap->Colors[c].Red;
             p[0][j].g = colmap->Colors[c].Green;
             p[0][j].b = colmap->Colors[c].Blue;
         }
     }
 

    
     /* Allocate image info */
     image = (animated_gif *)malloc(sizeof(animated_gif));
     if (image == NULL) 
     {
         fprintf(stderr, "Unable to allocate memory for animated_gif\n");
         /* Clean up */
         for (i = 0; i < n_images; i++) {
             free(p[i]);
         }
         free(p);
         free(width);
         free(height);
         return NULL;
     }
 
     /* Fill image fields */
     image->n_images = n_images;
     image->width = width;
     image->height = height;
     image->p = p;
     image->g = g;
 
 #if SOBELF_DEBUG
     printf("-> GIF w/ %d image(s) with first image of size %d x %d\n",
             image->n_images, image->width[0], image->height[0]);
 #endif
 
     return image;
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

//// Parallel version of store_pixels
int
store_pixels( char * filename, animated_gif * image, int parallelization_type )
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

    //// Parallelize over images?
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





///// Adapt to the type of parallelism needed
void apply_gray_filter(animated_gif *image, int parallelization_type)
{
    int i, j;
    pixel **p;
    p = image->p;

    // Check the global parallelization type
    if (parallelization_type == 1) { // Parallelize on the number of images
        // Parallelize the outer loop on images
        #pragma omp parallel for shared(image, p) schedule(dynamic) private(j)
        for (i = 0; i < image->n_images; i++) {
            // Apply gray filter on each pixel in the image
            for (j = 0; j < image->width[i] * image->height[i]; j++) {
                int moy;
                moy = (p[i][j].r + p[i][j].g + p[i][j].b) / 3;
                if (moy < 0) moy = 0;
                if (moy > 255) moy = 255;
                p[i][j].r = moy;
                p[i][j].g = moy;
                p[i][j].b = moy;
            }
        }
    }
    else if (parallelization_type == 2) { // Parallelize on the number of pixels
        // Parallelize the inner loop on pixels
        for (i = 0; i < image->n_images; i++) {
            #pragma omp parallel for shared(image, p) schedule(guided)
            for (j = 0; j < image->width[i] * image->height[i]; j++) {
                int moy;
                moy = (p[i][j].r + p[i][j].g + p[i][j].b) / 3;
                if (moy < 0) moy = 0;
                if (moy > 255) moy = 255;
                p[i][j].r = moy;
                p[i][j].g = moy;
                p[i][j].b = moy;
            }
        }
    }
    else {
        // Default case (no parallelization or another case)
        for (i = 0; i < image->n_images; i++) {
            for (j = 0; j < image->width[i] * image->height[i]; j++) {
                int moy;
                moy = (p[i][j].r + p[i][j].g + p[i][j].b) / 3;
                if (moy < 0) moy = 0;
                if (moy > 255) moy = 255;
                p[i][j].r = moy;
                p[i][j].g = moy;
                p[i][j].b = moy;
            }
        }
    }
}






#define CONV(l,c,nb_c) \
    (l)*(nb_c)+(c)

///// Function not used in the main
void apply_gray_line( animated_gif * image ) 
{
    int i, j, k ;
    pixel ** p ;

    p = image->p ;

    #pragma omp parallel for shared(image, p) schedule(dynamic) private(j, k) if (image->n_images >= 2) //i est automatiquement considéré comme privé
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

//// Parallel version
void
apply_blur_filter( animated_gif * image, int size, int threshold, int parallelization_type)
{
    int i, j, k ;
    int width, height ;
    int end = 0 ;
    int n_iter = 0 ;

    pixel ** p ;
    // new is declared inside the loop to avoid race conditions

    /* Get the pixels of all images */
    p = image->p ;

    /* Process all images */

    //// Parallelize on the images
    if (parallelization_type == 1) {
        #pragma omp parallel for private(j,k) shared(image, p) schedule(dynamic)
        for ( i = 0 ; i < image->n_images ; i++ )
        {
            n_iter = 0 ;
            width = image->width[i] ;
            height = image->height[i] ;

            /* Allocate array of new pixels */
            pixel * new = (pixel *)malloc(width * height * sizeof( pixel ) ) ;


            /* Perform at least one blur iteration */
            do
            {
                end = 1 ;
                n_iter++ ;


                for(j=0; j<height-1; j++)
                {
                    for(k=0; k<width-1; k++)
                    {
                        new[CONV(j,k,width)].r = p[i][CONV(j,k,width)].r ;
                        new[CONV(j,k,width)].g = p[i][CONV(j,k,width)].g ;
                        new[CONV(j,k,width)].b = p[i][CONV(j,k,width)].b ;
                    }
                }

                /* Apply blur on top part of image (10%) */
                for(j=size; j<height/10-size; j++)
                {
                    for(k=size; k<width-size; k++)
                    {
                        int stencil_j, stencil_k ;
                        int t_r = 0 ;
                        int t_g = 0 ;
                        int t_b = 0 ;

                        for ( stencil_j = -size ; stencil_j <= size ; stencil_j++ )
                        {
                            for ( stencil_k = -size ; stencil_k <= size ; stencil_k++ )
                            {
                                t_r += p[i][CONV(j+stencil_j,k+stencil_k,width)].r ;
                                t_g += p[i][CONV(j+stencil_j,k+stencil_k,width)].g ;
                                t_b += p[i][CONV(j+stencil_j,k+stencil_k,width)].b ;
                            }
                        }

                        new[CONV(j,k,width)].r = t_r / ( (2*size+1)*(2*size+1) ) ;
                        new[CONV(j,k,width)].g = t_g / ( (2*size+1)*(2*size+1) ) ;
                        new[CONV(j,k,width)].b = t_b / ( (2*size+1)*(2*size+1) ) ;
                    }
                }

                /* Copy the middle part of the image */
                // Pré-calcul des bornes avant la boucle
                int start_row = height / 10 - size;
                int end_row = (int)(height * 0.9 + size);  // On s'assure que c'est un entier
                int start_col = size;
                int end_col = width - size;

                for (j = start_row; j < end_row; j++) {
                    for (k = start_col; k < end_col; k++) {
                        new[CONV(j, k, width)].r = p[i][CONV(j, k, width)].r;
                        new[CONV(j, k, width)].g = p[i][CONV(j, k, width)].g;
                        new[CONV(j, k, width)].b = p[i][CONV(j, k, width)].b;
                    }
                }


                /* Apply blur on the bottom part of the image (10%) */
                for(j=height*0.9+size; j<height-size; j++)
                {
                    for(k=size; k<width-size; k++)
                    {
                        int stencil_j, stencil_k ;
                        int t_r = 0 ;
                        int t_g = 0 ;
                        int t_b = 0 ;

                        for ( stencil_j = -size ; stencil_j <= size ; stencil_j++ )
                        {
                            for ( stencil_k = -size ; stencil_k <= size ; stencil_k++ )
                            {
                                t_r += p[i][CONV(j+stencil_j,k+stencil_k,width)].r ;
                                t_g += p[i][CONV(j+stencil_j,k+stencil_k,width)].g ;
                                t_b += p[i][CONV(j+stencil_j,k+stencil_k,width)].b ;
                            }
                        }

                        new[CONV(j,k,width)].r = t_r / ( (2*size+1)*(2*size+1) ) ;
                        new[CONV(j,k,width)].g = t_g / ( (2*size+1)*(2*size+1) ) ;
                        new[CONV(j,k,width)].b = t_b / ( (2*size+1)*(2*size+1) ) ;
                    }
                }

                //// Parallelize this loop
                //// Potential race issue as we acces p[i] on multiple threads?
                //// Actually no as CONV is bijective
                //// works well on large images
                ////doesn't work if I try to parallelize the "image" as well

                for(j=1; j<height-1; j++)
                {
                    for(k=1; k<width-1; k++)
                    {

                        float diff_r ;
                        float diff_g ;
                        float diff_b ;

                        diff_r = (new[CONV(j  ,k  ,width)].r - p[i][CONV(j  ,k  ,width)].r) ;
                        diff_g = (new[CONV(j  ,k  ,width)].g - p[i][CONV(j  ,k  ,width)].g) ;
                        diff_b = (new[CONV(j  ,k  ,width)].b - p[i][CONV(j  ,k  ,width)].b) ;

                        if ( diff_r > threshold || -diff_r > threshold 
                                ||
                                    diff_g > threshold || -diff_g > threshold
                                    ||
                                    diff_b > threshold || -diff_b > threshold
                            ) {
                            end = 0 ;
                        }

                        p[i][CONV(j  ,k  ,width)].r = new[CONV(j  ,k  ,width)].r ;
                        p[i][CONV(j  ,k  ,width)].g = new[CONV(j  ,k  ,width)].g ;
                        p[i][CONV(j  ,k  ,width)].b = new[CONV(j  ,k  ,width)].b ;
                    }
                }

            }
            while ( threshold > 0 && !end ) ;

    #if SOBELF_DEBUG
        printf( "BLUR: number of iterations for image %d\n", n_iter ) ;
    #endif

            free (new) ;
        }
    }

    //// Parallelize on the pixels
    else if (parallelization_type == 2) {
        for ( i = 0 ; i < image->n_images ; i++ )
        {
            n_iter = 0 ;
            width = image->width[i] ;
            height = image->height[i] ;

            /* Allocate array of new pixels */
            pixel * new = (pixel *)malloc(width * height * sizeof( pixel ) ) ;


            /* Perform at least one blur iteration */
            do
            {
                end = 1 ;
                n_iter++ ;


                #pragma omp parallel for default(shared) collapse(2) private(j ,k) schedule(guided) if(height * width >= 1000)
                for(j=0; j<height-1; j++)
                {
                    for(k=0; k<width-1; k++)
                    {
                        new[CONV(j,k,width)].r = p[i][CONV(j,k,width)].r ;
                        new[CONV(j,k,width)].g = p[i][CONV(j,k,width)].g ;
                        new[CONV(j,k,width)].b = p[i][CONV(j,k,width)].b ;
                    }
                }

                /* Apply blur on top part of image (10%) */
                #pragma omp parallel for default(shared) collapse(2) private(j,k) schedule(guided) if(height * width >= 1000)
                for(j=size; j<height/10-size; j++)
                {
                    for(k=size; k<width-size; k++)
                    {
                        int stencil_j, stencil_k ;
                        int t_r = 0 ;
                        int t_g = 0 ;
                        int t_b = 0 ;

                        for ( stencil_j = -size ; stencil_j <= size ; stencil_j++ )
                        {
                            for ( stencil_k = -size ; stencil_k <= size ; stencil_k++ )
                            {
                                t_r += p[i][CONV(j+stencil_j,k+stencil_k,width)].r ;
                                t_g += p[i][CONV(j+stencil_j,k+stencil_k,width)].g ;
                                t_b += p[i][CONV(j+stencil_j,k+stencil_k,width)].b ;
                            }
                        }

                        new[CONV(j,k,width)].r = t_r / ( (2*size+1)*(2*size+1) ) ;
                        new[CONV(j,k,width)].g = t_g / ( (2*size+1)*(2*size+1) ) ;
                        new[CONV(j,k,width)].b = t_b / ( (2*size+1)*(2*size+1) ) ;
                    }
                }

                /* Copy the middle part of the image */
                // Pré-calcul des bornes avant la boucle
                int start_row = height / 10 - size;
                int end_row = (int)(height * 0.9 + size);  // On s'assure que c'est un entier
                int start_col = size;
                int end_col = width - size;

                #pragma omp parallel for default(shared) private(j, k) collapse(2) schedule(guided, 16) if(height * width >= 1000)
                for (j = start_row; j < end_row; j++) {
                    for (k = start_col; k < end_col; k++) {
                        new[CONV(j, k, width)].r = p[i][CONV(j, k, width)].r;
                        new[CONV(j, k, width)].g = p[i][CONV(j, k, width)].g;
                        new[CONV(j, k, width)].b = p[i][CONV(j, k, width)].b;
                    }
                }


                /* Apply blur on the bottom part of the image (10%) */
                #pragma omp parallel for default(shared) collapse(2) schedule(guided) if(height * width >= 1000)
                for(j=height*0.9+size; j<height-size; j++)
                {
                    for(k=size; k<width-size; k++)
                    {
                        int stencil_j, stencil_k ;
                        int t_r = 0 ;
                        int t_g = 0 ;
                        int t_b = 0 ;

                        for ( stencil_j = -size ; stencil_j <= size ; stencil_j++ )
                        {
                            for ( stencil_k = -size ; stencil_k <= size ; stencil_k++ )
                            {
                                t_r += p[i][CONV(j+stencil_j,k+stencil_k,width)].r ;
                                t_g += p[i][CONV(j+stencil_j,k+stencil_k,width)].g ;
                                t_b += p[i][CONV(j+stencil_j,k+stencil_k,width)].b ;
                            }
                        }

                        new[CONV(j,k,width)].r = t_r / ( (2*size+1)*(2*size+1) ) ;
                        new[CONV(j,k,width)].g = t_g / ( (2*size+1)*(2*size+1) ) ;
                        new[CONV(j,k,width)].b = t_b / ( (2*size+1)*(2*size+1) ) ;
                    }
                }

                //// Parallelize this loop
                //// Potential race issue as we acces p[i] on multiple threads?
                //// Actually no as CONV is bijective
                //// works well on large images
                ////doesn't work if I try to parallelize the "image"

                #pragma omp parallel for default(shared) private(j, k) collapse(2) schedule(guided) if(height * width >= 1000)
                for(j=1; j<height-1; j++)
                {
                    for(k=1; k<width-1; k++)
                    {

                        float diff_r ;
                        float diff_g ;
                        float diff_b ;

                        diff_r = (new[CONV(j  ,k  ,width)].r - p[i][CONV(j  ,k  ,width)].r) ;
                        diff_g = (new[CONV(j  ,k  ,width)].g - p[i][CONV(j  ,k  ,width)].g) ;
                        diff_b = (new[CONV(j  ,k  ,width)].b - p[i][CONV(j  ,k  ,width)].b) ;

                        if ( diff_r > threshold || -diff_r > threshold 
                                ||
                                    diff_g > threshold || -diff_g > threshold
                                    ||
                                    diff_b > threshold || -diff_b > threshold
                            ) {
                            end = 0 ;
                        }

                        p[i][CONV(j  ,k  ,width)].r = new[CONV(j  ,k  ,width)].r ;
                        p[i][CONV(j  ,k  ,width)].g = new[CONV(j  ,k  ,width)].g ;
                        p[i][CONV(j  ,k  ,width)].b = new[CONV(j  ,k  ,width)].b ;
                    }
                }

            }
            while ( threshold > 0 && !end ) ;

    #if SOBELF_DEBUG
        printf( "BLUR: number of iterations for image %d\n", n_iter ) ;
    #endif

            free (new) ;
        }
    }


    //// Don't parallelize
    else{
        for ( i = 0 ; i < image->n_images ; i++ )
        {
            n_iter = 0 ;
            width = image->width[i] ;
            height = image->height[i] ;

            /* Allocate array of new pixels */
            pixel * new = (pixel *)malloc(width * height * sizeof( pixel ) ) ;


            /* Perform at least one blur iteration */
            do
            {
                end = 1 ;
                n_iter++ ;


                for(j=0; j<height-1; j++)
                {
                    for(k=0; k<width-1; k++)
                    {
                        new[CONV(j,k,width)].r = p[i][CONV(j,k,width)].r ;
                        new[CONV(j,k,width)].g = p[i][CONV(j,k,width)].g ;
                        new[CONV(j,k,width)].b = p[i][CONV(j,k,width)].b ;
                    }
                }

                /* Apply blur on top part of image (10%) */
                for(j=size; j<height/10-size; j++)
                {
                    for(k=size; k<width-size; k++)
                    {
                        int stencil_j, stencil_k ;
                        int t_r = 0 ;
                        int t_g = 0 ;
                        int t_b = 0 ;

                        for ( stencil_j = -size ; stencil_j <= size ; stencil_j++ )
                        {
                            for ( stencil_k = -size ; stencil_k <= size ; stencil_k++ )
                            {
                                t_r += p[i][CONV(j+stencil_j,k+stencil_k,width)].r ;
                                t_g += p[i][CONV(j+stencil_j,k+stencil_k,width)].g ;
                                t_b += p[i][CONV(j+stencil_j,k+stencil_k,width)].b ;
                            }
                        }

                        new[CONV(j,k,width)].r = t_r / ( (2*size+1)*(2*size+1) ) ;
                        new[CONV(j,k,width)].g = t_g / ( (2*size+1)*(2*size+1) ) ;
                        new[CONV(j,k,width)].b = t_b / ( (2*size+1)*(2*size+1) ) ;
                    }
                }

                /* Copy the middle part of the image */
                // Pré-calcul des bornes avant la boucle
                int start_row = height / 10 - size;
                int end_row = (int)(height * 0.9 + size);  // On s'assure que c'est un entier
                int start_col = size;
                int end_col = width - size;

                for (j = start_row; j < end_row; j++) {
                    for (k = start_col; k < end_col; k++) {
                        new[CONV(j, k, width)].r = p[i][CONV(j, k, width)].r;
                        new[CONV(j, k, width)].g = p[i][CONV(j, k, width)].g;
                        new[CONV(j, k, width)].b = p[i][CONV(j, k, width)].b;
                    }
                }


                /* Apply blur on the bottom part of the image (10%) */
                for(j=height*0.9+size; j<height-size; j++)
                {
                    for(k=size; k<width-size; k++)
                    {
                        int stencil_j, stencil_k ;
                        int t_r = 0 ;
                        int t_g = 0 ;
                        int t_b = 0 ;

                        for ( stencil_j = -size ; stencil_j <= size ; stencil_j++ )
                        {
                            for ( stencil_k = -size ; stencil_k <= size ; stencil_k++ )
                            {
                                t_r += p[i][CONV(j+stencil_j,k+stencil_k,width)].r ;
                                t_g += p[i][CONV(j+stencil_j,k+stencil_k,width)].g ;
                                t_b += p[i][CONV(j+stencil_j,k+stencil_k,width)].b ;
                            }
                        }

                        new[CONV(j,k,width)].r = t_r / ( (2*size+1)*(2*size+1) ) ;
                        new[CONV(j,k,width)].g = t_g / ( (2*size+1)*(2*size+1) ) ;
                        new[CONV(j,k,width)].b = t_b / ( (2*size+1)*(2*size+1) ) ;
                    }
                }

                //// Parallelize this loop
                //// Potential race issue as we acces p[i] on multiple threads?
                //// Actually no as CONV is bijective
                //// works well on large images
                ////doesn't work if I try to parallelize the "image"

                for(j=1; j<height-1; j++)
                {
                    for(k=1; k<width-1; k++)
                    {

                        float diff_r ;
                        float diff_g ;
                        float diff_b ;

                        diff_r = (new[CONV(j  ,k  ,width)].r - p[i][CONV(j  ,k  ,width)].r) ;
                        diff_g = (new[CONV(j  ,k  ,width)].g - p[i][CONV(j  ,k  ,width)].g) ;
                        diff_b = (new[CONV(j  ,k  ,width)].b - p[i][CONV(j  ,k  ,width)].b) ;

                        if ( diff_r > threshold || -diff_r > threshold 
                                ||
                                    diff_g > threshold || -diff_g > threshold
                                    ||
                                    diff_b > threshold || -diff_b > threshold
                            ) {
                            end = 0 ;
                        }

                        p[i][CONV(j  ,k  ,width)].r = new[CONV(j  ,k  ,width)].r ;
                        p[i][CONV(j  ,k  ,width)].g = new[CONV(j  ,k  ,width)].g ;
                        p[i][CONV(j  ,k  ,width)].b = new[CONV(j  ,k  ,width)].b ;
                    }
                }

            }
            while ( threshold > 0 && !end ) ;

    #if SOBELF_DEBUG
        printf( "BLUR: number of iterations for image %d\n", n_iter ) ;
    #endif

            free (new) ;
        }
    }

}






//// Parallel version
void
apply_sobel_filter( animated_gif * image, int parallelization_type)
{
    int i, j, k ;
    int width, height ;

    pixel ** p ;

    p = image->p ;

    //// Parallelize on the images
    if (parallelization_type == 1) {
        #pragma omp parallel for private(j,k) shared(image, p) schedule(dynamic)
        for ( i = 0 ; i < image->n_images ; i++ )
        {
            width = image->width[i] ;
            height = image->height[i] ;

            pixel * sobel ;
            sobel = (pixel *)malloc(width * height * sizeof( pixel ) ) ;

            for(j=1; j<height-1; j++)
            {
                for(k=1; k<width-1; k++)
                {
                    int pixel_blue_no, pixel_blue_n, pixel_blue_ne;
                    int pixel_blue_so, pixel_blue_s, pixel_blue_se;
                    int pixel_blue_o , pixel_blue  , pixel_blue_e ;

                    float deltaX_blue ;
                    float deltaY_blue ;
                    float val_blue;

                    pixel_blue_no = p[i][CONV(j-1,k-1,width)].b ;
                    pixel_blue_n  = p[i][CONV(j-1,k  ,width)].b ;
                    pixel_blue_ne = p[i][CONV(j-1,k+1,width)].b ;
                    pixel_blue_so = p[i][CONV(j+1,k-1,width)].b ;
                    pixel_blue_s  = p[i][CONV(j+1,k  ,width)].b ;
                    pixel_blue_se = p[i][CONV(j+1,k+1,width)].b ;
                    pixel_blue_o  = p[i][CONV(j  ,k-1,width)].b ;
                    pixel_blue    = p[i][CONV(j  ,k  ,width)].b ;
                    pixel_blue_e  = p[i][CONV(j  ,k+1,width)].b ;

                    deltaX_blue = -pixel_blue_no + pixel_blue_ne - 2*pixel_blue_o + 2*pixel_blue_e - pixel_blue_so + pixel_blue_se;             

                    deltaY_blue = pixel_blue_se + 2*pixel_blue_s + pixel_blue_so - pixel_blue_ne - 2*pixel_blue_n - pixel_blue_no;

                    val_blue = sqrt(deltaX_blue * deltaX_blue + deltaY_blue * deltaY_blue)/4;


                    if ( val_blue > 50 ) 
                    {
                        sobel[CONV(j  ,k  ,width)].r = 255 ;
                        sobel[CONV(j  ,k  ,width)].g = 255 ;
                        sobel[CONV(j  ,k  ,width)].b = 255 ;
                    } else
                    {
                        sobel[CONV(j  ,k  ,width)].r = 0 ;
                        sobel[CONV(j  ,k  ,width)].g = 0 ;
                        sobel[CONV(j  ,k  ,width)].b = 0 ;
                    }
                }
            }

            for(j=1; j<height-1; j++)
            {
                for(k=1; k<width-1; k++)
                {
                    p[i][CONV(j  ,k  ,width)].r = sobel[CONV(j  ,k  ,width)].r ;
                    p[i][CONV(j  ,k  ,width)].g = sobel[CONV(j  ,k  ,width)].g ;
                    p[i][CONV(j  ,k  ,width)].b = sobel[CONV(j  ,k  ,width)].b ;
                }
            }

            free (sobel) ;
        }
    }

    //// Parallelize on the pixels
    else if (parallelization_type == 2) {
        for ( i = 0 ; i < image->n_images ; i++ )
        {
            width = image->width[i] ;
            height = image->height[i] ;

            pixel * sobel ;
            sobel = (pixel *)malloc(width * height * sizeof( pixel ) ) ;

            #pragma omp parallel for default(shared) private(j, k) collapse(2) schedule(guided) if(height * width >= 1000)
            for(j=1; j<height-1; j++)
            {
                for(k=1; k<width-1; k++)
                {
                    int pixel_blue_no, pixel_blue_n, pixel_blue_ne;
                    int pixel_blue_so, pixel_blue_s, pixel_blue_se;
                    int pixel_blue_o , pixel_blue  , pixel_blue_e ;

                    float deltaX_blue ;
                    float deltaY_blue ;
                    float val_blue;

                    pixel_blue_no = p[i][CONV(j-1,k-1,width)].b ;
                    pixel_blue_n  = p[i][CONV(j-1,k  ,width)].b ;
                    pixel_blue_ne = p[i][CONV(j-1,k+1,width)].b ;
                    pixel_blue_so = p[i][CONV(j+1,k-1,width)].b ;
                    pixel_blue_s  = p[i][CONV(j+1,k  ,width)].b ;
                    pixel_blue_se = p[i][CONV(j+1,k+1,width)].b ;
                    pixel_blue_o  = p[i][CONV(j  ,k-1,width)].b ;
                    pixel_blue    = p[i][CONV(j  ,k  ,width)].b ;
                    pixel_blue_e  = p[i][CONV(j  ,k+1,width)].b ;

                    deltaX_blue = -pixel_blue_no + pixel_blue_ne - 2*pixel_blue_o + 2*pixel_blue_e - pixel_blue_so + pixel_blue_se;             

                    deltaY_blue = pixel_blue_se + 2*pixel_blue_s + pixel_blue_so - pixel_blue_ne - 2*pixel_blue_n - pixel_blue_no;

                    val_blue = sqrt(deltaX_blue * deltaX_blue + deltaY_blue * deltaY_blue)/4;


                    if ( val_blue > 50 ) 
                    {
                        sobel[CONV(j  ,k  ,width)].r = 255 ;
                        sobel[CONV(j  ,k  ,width)].g = 255 ;
                        sobel[CONV(j  ,k  ,width)].b = 255 ;
                    } else
                    {
                        sobel[CONV(j  ,k  ,width)].r = 0 ;
                        sobel[CONV(j  ,k  ,width)].g = 0 ;
                        sobel[CONV(j  ,k  ,width)].b = 0 ;
                    }
                }
            }

            #pragma omp parallel for default(shared) private(j, k) collapse(2) schedule(guided) if(height * width >= 1000)
            for(j=1; j<height-1; j++)
            {
                for(k=1; k<width-1; k++)
                {
                    p[i][CONV(j  ,k  ,width)].r = sobel[CONV(j  ,k  ,width)].r ;
                    p[i][CONV(j  ,k  ,width)].g = sobel[CONV(j  ,k  ,width)].g ;
                    p[i][CONV(j  ,k  ,width)].b = sobel[CONV(j  ,k  ,width)].b ;
                }
            }

            free (sobel) ;
        }
    }

    //// Don't parallelize
    else {
        for ( i = 0 ; i < image->n_images ; i++ )
        {
            width = image->width[i] ;
            height = image->height[i] ;

            pixel * sobel ;
            sobel = (pixel *)malloc(width * height * sizeof( pixel ) ) ;

            for(j=1; j<height-1; j++)
            {
                for(k=1; k<width-1; k++)
                {
                    int pixel_blue_no, pixel_blue_n, pixel_blue_ne;
                    int pixel_blue_so, pixel_blue_s, pixel_blue_se;
                    int pixel_blue_o , pixel_blue  , pixel_blue_e ;

                    float deltaX_blue ;
                    float deltaY_blue ;
                    float val_blue;

                    pixel_blue_no = p[i][CONV(j-1,k-1,width)].b ;
                    pixel_blue_n  = p[i][CONV(j-1,k  ,width)].b ;
                    pixel_blue_ne = p[i][CONV(j-1,k+1,width)].b ;
                    pixel_blue_so = p[i][CONV(j+1,k-1,width)].b ;
                    pixel_blue_s  = p[i][CONV(j+1,k  ,width)].b ;
                    pixel_blue_se = p[i][CONV(j+1,k+1,width)].b ;
                    pixel_blue_o  = p[i][CONV(j  ,k-1,width)].b ;
                    pixel_blue    = p[i][CONV(j  ,k  ,width)].b ;
                    pixel_blue_e  = p[i][CONV(j  ,k+1,width)].b ;

                    deltaX_blue = -pixel_blue_no + pixel_blue_ne - 2*pixel_blue_o + 2*pixel_blue_e - pixel_blue_so + pixel_blue_se;             

                    deltaY_blue = pixel_blue_se + 2*pixel_blue_s + pixel_blue_so - pixel_blue_ne - 2*pixel_blue_n - pixel_blue_no;

                    val_blue = sqrt(deltaX_blue * deltaX_blue + deltaY_blue * deltaY_blue)/4;


                    if ( val_blue > 50 ) 
                    {
                        sobel[CONV(j  ,k  ,width)].r = 255 ;
                        sobel[CONV(j  ,k  ,width)].g = 255 ;
                        sobel[CONV(j  ,k  ,width)].b = 255 ;
                    } else
                    {
                        sobel[CONV(j  ,k  ,width)].r = 0 ;
                        sobel[CONV(j  ,k  ,width)].g = 0 ;
                        sobel[CONV(j  ,k  ,width)].b = 0 ;
                    }
                }
            }

            for(j=1; j<height-1; j++)
            {
                for(k=1; k<width-1; k++)
                {
                    p[i][CONV(j  ,k  ,width)].r = sobel[CONV(j  ,k  ,width)].r ;
                    p[i][CONV(j  ,k  ,width)].g = sobel[CONV(j  ,k  ,width)].g ;
                    p[i][CONV(j  ,k  ,width)].b = sobel[CONV(j  ,k  ,width)].b ;
                }
            }

            free (sobel) ;
        }
    }
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

    duration_file = fopen("durations_para_OpenMP.csv", "a");
    if (duration_file == NULL) {
        perror("Erreur lors de l'ouverture du fichier");
        return 1;
    }

    /* Check if the file is empty to write the header */
    fseek(duration_file, 0, SEEK_END);
    if (ftell(duration_file) == 0) {
        fprintf(duration_file, "Filename,Using_OpenMP,Number Images,Number Pixels,Import Duration,Gray Filter Duration,Blur Filter Duration,Sobel Filter Duration,Export Duration\n");
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

    //// Code to know if we should parallelize on the number of images in the gif 
    //// or the number of pixels in an image

    //// if we parallelize on the number of images, we can't parallelize on the pixels
    //// if we parallelize on the pixels, we can't parallelize on the images

    //// if image->n_images >= 8, we parallelize on the images
    //// if image->width * image->height >= 1000, we parallelize on the pixels

    //// I want to set a global variable that indicates the type of parallelization
    //// and use it in the functions

    int parallelization_type;
    char * Using_OpenMP ;
    if (image->n_images >= 8) {
        parallelization_type = PARALLELIZE_IMAGES;
        Using_OpenMP = "Using OpenMP on images";}
    else if (image->width[0] * image->height[0] >= 1000) {
        parallelization_type = PARALLELIZE_PIXELS;
        Using_OpenMP = "Using OpenMP on pixels";}
    else {
        parallelization_type = NO_PARALLELIZATION;
        Using_OpenMP = "Not using OpenMP";
    }

    int nb_images = image->n_images;
    int nb_pixels = image->width[0] * image->height[0];

    // printf("Nombre d'images: %d\n", image->n_images);
    // printf("Nombre de pixels: %d\n", image->width[0] * image->height[0]);
    // printf("Parallelization type: %d\n", parallelization_type);



    /* FILTER Timer start */
    gettimeofday(&t1, NULL);

    /* Gray Filter Timer start */
    gettimeofday(&t1, NULL);
    apply_gray_filter( image, parallelization_type) ;
    gettimeofday(&t2, NULL);
    gray_duration = (t2.tv_sec -t1.tv_sec)+((t2.tv_usec-t1.tv_usec)/1e6);

#if PRINT_TIME
    printf( "Gray filter done in %lf s\n", gray_duration );
#endif

    /* Blur Filter Timer start */
    gettimeofday(&t1, NULL);
    apply_blur_filter( image, 5, 20, parallelization_type) ;
    gettimeofday(&t2, NULL);
    blur_duration = (t2.tv_sec -t1.tv_sec)+((t2.tv_usec-t1.tv_usec)/1e6);

#if PRINT_TIME
    printf( "Blur filter done in %lf s\n", blur_duration );
#endif

    /* Sobel Filter Timer start */
    gettimeofday(&t1, NULL);
    apply_sobel_filter( image, parallelization_type) ;
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
    if ( !store_pixels( output_filename, image, parallelization_type ) ) { return 1 ; }

    /* EXPORT Timer stop */
    gettimeofday(&t2, NULL);

    export_duration = (t2.tv_sec -t1.tv_sec)+((t2.tv_usec-t1.tv_usec)/1e6);

#if PRINT_TIME
    printf( "Export done in %lf s in file %s\n", export_duration, output_filename );
#endif

    /* Write durations to file */
    fprintf(duration_file, "%s,%s,%d, %d, %lf,%lf,%lf,%lf,%lf\n", input_filename, Using_OpenMP, nb_images, nb_pixels, import_duration, gray_duration, blur_duration, sobel_duration, export_duration);

    /* Close the file */
    fclose(duration_file);

    return 0 ;
}

