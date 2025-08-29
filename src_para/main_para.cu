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

// CUDA-specific headers
#include <cuda.h>

// MPI headers
#include <mpi.h>

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
animated_gif *load_pixels(char *filename) {
    GifFileType *g;
    ColorMapObject *colmap;
    int error;
    int n_images;
    int *width;
    int *height;
    pixel **p;
    int i;
    animated_gif *image;

    /* Open the GIF image (read mode) */
    g = DGifOpenFileName(filename, &error);
    if (g == NULL) {
        fprintf(stderr, "Error DGifOpenFileName %s\n", filename);
        return NULL;
    }

    /* Read the GIF image */
    error = DGifSlurp(g);
    if (error != GIF_OK) {
        fprintf(stderr, "Error DGifSlurp: %d <%s>\n", error,
                GifErrorString(g->Error));
        return NULL;
    }

    /* Grab the number of images and the size of each image */
    n_images = g->ImageCount;

    width = (int *)malloc(n_images * sizeof(int));
    if (width == NULL) {
        fprintf(stderr, "Unable to allocate width of size %d\n", n_images);
        return 0;
    }

    height = (int *)malloc(n_images * sizeof(int));
    if (height == NULL) {
        fprintf(stderr, "Unable to allocate height of size %d\n", n_images);
        return 0;
    }

    /* Fill the width and height */
    for (i = 0; i < n_images; i++) {
        width[i] = g->SavedImages[i].ImageDesc.Width;
        height[i] = g->SavedImages[i].ImageDesc.Height;

#if SOBELF_DEBUG
        printf("Image %d: l:%d t:%d w:%d h:%d interlace:%d localCM:%p\n", i,
               g->SavedImages[i].ImageDesc.Left,
               g->SavedImages[i].ImageDesc.Top,
               g->SavedImages[i].ImageDesc.Width,
               g->SavedImages[i].ImageDesc.Height,
               g->SavedImages[i].ImageDesc.Interlace,
               g->SavedImages[i].ImageDesc.ColorMap);
#endif
    }

    /* Get the global colormap */
    colmap = g->SColorMap;
    if (colmap == NULL) {
        fprintf(stderr, "Error global colormap is NULL\n");
        return NULL;
    }

#if SOBELF_DEBUG
    printf("Global color map: count:%d bpp:%d sort:%d\n",
           g->SColorMap->ColorCount, g->SColorMap->BitsPerPixel,
           g->SColorMap->SortFlag);
#endif

    /* Allocate the array of pixels to be returned */
    p = (pixel **)malloc(n_images * sizeof(pixel *));
    if (p == NULL) {
        fprintf(stderr, "Unable to allocate array of %d images\n", n_images);
        return NULL;
    }

    for (i = 0; i < n_images; i++) {
        p[i] = (pixel *)malloc(width[i] * height[i] * sizeof(pixel));
        if (p[i] == NULL) {
            fprintf(stderr, "Unable to allocate %d-th array of %d pixels\n", i,
                    width[i] * height[i]);
            return NULL;
        }
    }

    /* Fill pixels */

    /* For each image */
    for (i = 0; i < n_images; i++) {
        int j;

        /* Get the local colormap if needed */
        if (g->SavedImages[i].ImageDesc.ColorMap) {

            /* TODO No support for local color map */
            fprintf(stderr,
                    "Error: application does not support local colormap\n");
            return NULL;

            colmap = g->SavedImages[i].ImageDesc.ColorMap;
        }

        /* Traverse the image and fill pixels */
        for (j = 0; j < width[i] * height[i]; j++) {
            int c;

            c = g->SavedImages[i].RasterBits[j];

            p[i][j].r = colmap->Colors[c].Red;
            p[i][j].g = colmap->Colors[c].Green;
            p[i][j].b = colmap->Colors[c].Blue;
        }
    }

    /* Allocate image info */
    image = (animated_gif *)malloc(sizeof(animated_gif));
    if (image == NULL) {
        fprintf(stderr, "Unable to allocate memory for animated_gif\n");
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





// animated_gif *
// load_pixels(char * filename) 
// {
//     GifFileType * g;
//     ColorMapObject * colmap;
//     int error;
//     int n_images;
//     int * width;
//     int * height;
//     pixel ** p;
//     int i;
//     animated_gif * image;

//     /* Open the GIF image (read mode) */
//     g = DGifOpenFileName(filename, &error);
//     if (g == NULL) 
//     {
//         fprintf(stderr, "Error DGifOpenFileName %s\n", filename);
//         return NULL;
//     }

//     /* Read the GIF image */
//     error = DGifSlurp(g);
//     if (error != GIF_OK)
//     {
//         fprintf(stderr, 
//                 "Error DGifSlurp: %d <%s>\n", error, GifErrorString(g->Error));
//         return NULL;
//     }

//     /* Grab the number of images and the size of each image */
//     n_images = g->ImageCount;

//     width = (int *)malloc(n_images * sizeof(int));
//     if (width == NULL)
//     {
//         fprintf(stderr, "Unable to allocate width of size %d\n", n_images);
//         return NULL;
//     }

//     height = (int *)malloc(n_images * sizeof(int));
//     if (height == NULL)
//     {
//         fprintf(stderr, "Unable to allocate height of size %d\n", n_images);
//         free(width);
//         return NULL;
//     }

//     /* Fill the width and height - keep this sequential, it's lightweight */
//     for (i = 0; i < n_images; i++) 
//     {
//         width[i] = g->SavedImages[i].ImageDesc.Width;
//         height[i] = g->SavedImages[i].ImageDesc.Height;

// #if SOBELF_DEBUG
//         printf("Image %d: l:%d t:%d w:%d h:%d interlace:%d localCM:%p\n",
//                 i, 
//                 g->SavedImages[i].ImageDesc.Left,
//                 g->SavedImages[i].ImageDesc.Top,
//                 g->SavedImages[i].ImageDesc.Width,
//                 g->SavedImages[i].ImageDesc.Height,
//                 g->SavedImages[i].ImageDesc.Interlace,
//                 g->SavedImages[i].ImageDesc.ColorMap
//                 );
// #endif
//     }

//     /* Get the global colormap */
//     colmap = g->SColorMap;
//     if (colmap == NULL) 
//     {
//         fprintf(stderr, "Error global colormap is NULL\n");
//         free(width);
//         free(height);
//         return NULL;
//     }

// #if SOBELF_DEBUG
//     printf("Global color map: count:%d bpp:%d sort:%d\n",
//             g->SColorMap->ColorCount,
//             g->SColorMap->BitsPerPixel,
//             g->SColorMap->SortFlag
//             );
// #endif

//     /* Check for local colormaps before any parallel region */
//     for (i = 0; i < n_images; i++)
//     {
//         if (g->SavedImages[i].ImageDesc.ColorMap)
//         {
//             fprintf(stderr, "Error: application does not support local colormap\n");
//             free(width);
//             free(height);
//             return NULL;
//         }
//     }

//     /* Allocate the array of pixels to be returned */
//     p = (pixel **)malloc(n_images * sizeof(pixel *));
//     if (p == NULL)
//     {
//         fprintf(stderr, "Unable to allocate array of %d images\n", n_images);
//         free(width);
//         free(height);
//         return NULL;
//     }

//     /* Allocate memory for each image - keep sequential for proper error handling */
//     for (i = 0; i < n_images; i++) 
//     {
//         p[i] = (pixel *)malloc(width[i] * height[i] * sizeof(pixel));
//         if (p[i] == NULL)
//         {
//             fprintf(stderr, "Unable to allocate %d-th array of %d pixels\n",
//                   i, width[i] * height[i]);
            
//             /* Clean up already allocated memory */
//             for (int j = 0; j < i; j++) {
//                 free(p[j]);
//             }
//             free(p);
//             free(width);
//             free(height);
//             return NULL;
//         }
//     }
    
//     /* Set the number of threads explicitly based on available cores */
//     #pragma omp parallel
//     {
//         #pragma omp master
//         {
//             #if SOBELF_DEBUG
//             printf("Running with %d threads\n", omp_get_num_threads());
//             #endif
//         }
//     }
    
//     /* Fill pixels with improved parallelization */
//     if (n_images > 1) 
//     {
//         /* For multiple images: use a thread pool with dynamic scheduling */
//         #pragma omp parallel for schedule(dynamic, 1) proc_bind(spread)
//         for (i = 0; i < n_images; i++)
//         {
//             int j;
//             int w = width[i];
//             int h = height[i];
//             int pixel_count = w * h;
            
//             /* For large images, parallelize pixel processing with chunking for better cache utilization */
//             if (pixel_count > 100000) 
//             {
//                 const int chunk_size = 8192; /* Adjust based on cache size */
//                 #pragma omp parallel for schedule(dynamic, chunk_size) if(pixel_count > 500000)
//                 for (j = 0; j < pixel_count; j++) 
//                 {
//                     int c = g->SavedImages[i].RasterBits[j];
//                     p[i][j].r = colmap->Colors[c].Red;
//                     p[i][j].g = colmap->Colors[c].Green;
//                     p[i][j].b = colmap->Colors[c].Blue;
//                 }
//             } 
//             else 
//             {
//                 /* For smaller images, use vectorization hints */
//                 #pragma omp simd
//                 for (j = 0; j < pixel_count; j++) 
//                 {
//                     int c = g->SavedImages[i].RasterBits[j];
//                     p[i][j].r = colmap->Colors[c].Red;
//                     p[i][j].g = colmap->Colors[c].Green;
//                     p[i][j].b = colmap->Colors[c].Blue;
//                 }
//             }
//         }
//     } 
//     else 
//     {
//         /* For a single image: optimize based on image size */
//         int pixel_count = width[0] * height[0];
        
//         if (pixel_count > 500000) 
//         {
//             /* Very large image: use multiple threads with cache-friendly chunking */
//             const int chunk_size = 16384;
//             #pragma omp parallel for schedule(dynamic, chunk_size) proc_bind(close)
//             for (int j = 0; j < pixel_count; j++) 
//             {
//                 int c = g->SavedImages[0].RasterBits[j];
//                 p[0][j].r = colmap->Colors[c].Red;
//                 p[0][j].g = colmap->Colors[c].Green;
//                 p[0][j].b = colmap->Colors[c].Blue;
//             }
//         } 
//         else if (pixel_count > 50000) 
//         {
//             /* Medium image: basic parallelization with SIMD hints */
//             #pragma omp parallel for simd
//             for (int j = 0; j < pixel_count; j++) 
//             {
//                 int c = g->SavedImages[0].RasterBits[j];
//                 p[0][j].r = colmap->Colors[c].Red;
//                 p[0][j].g = colmap->Colors[c].Green;
//                 p[0][j].b = colmap->Colors[c].Blue;
//             }
//         } 
//         else 
//         {
//             /* Small image: just use SIMD */
//             #pragma omp simd
//             for (int j = 0; j < pixel_count; j++) 
//             {
//                 int c = g->SavedImages[0].RasterBits[j];
//                 p[0][j].r = colmap->Colors[c].Red;
//                 p[0][j].g = colmap->Colors[c].Green;
//                 p[0][j].b = colmap->Colors[c].Blue;
//             }
//         }
//     }

//     /* Allocate image info */
//     image = (animated_gif *)malloc(sizeof(animated_gif));
//     if (image == NULL) 
//     {
//         fprintf(stderr, "Unable to allocate memory for animated_gif\n");
//         /* Clean up */
//         for (i = 0; i < n_images; i++) {
//             free(p[i]);
//         }
//         free(p);
//         free(width);
//         free(height);
//         return NULL;
//     }

//     /* Fill image fields */
//     image->n_images = n_images;
//     image->width = width;
//     image->height = height;
//     image->p = p;
//     image->g = g;

// #if SOBELF_DEBUG
//     printf("-> GIF w/ %d image(s) with first image of size %d x %d\n",
//             image->n_images, image->width[0], image->height[0]);
// #endif

//     return image;
// }











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
            pixel * new_pixels = (pixel *)malloc(width * height * sizeof( pixel ) ) ;


            /* Perform at least one blur iteration */
            do
            {
                end = 1 ;
                n_iter++ ;


                for(j=0; j<height-1; j++)
                {
                    for(k=0; k<width-1; k++)
                    {
                        new_pixels[CONV(j,k,width)].r = p[i][CONV(j,k,width)].r ;
                        new_pixels[CONV(j,k,width)].g = p[i][CONV(j,k,width)].g ;
                        new_pixels[CONV(j,k,width)].b = p[i][CONV(j,k,width)].b ;
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

                        new_pixels[CONV(j,k,width)].r = t_r / ( (2*size+1)*(2*size+1) ) ;
                        new_pixels[CONV(j,k,width)].g = t_g / ( (2*size+1)*(2*size+1) ) ;
                        new_pixels[CONV(j,k,width)].b = t_b / ( (2*size+1)*(2*size+1) ) ;
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
                        new_pixels[CONV(j, k, width)].r = p[i][CONV(j, k, width)].r;
                        new_pixels[CONV(j, k, width)].g = p[i][CONV(j, k, width)].g;
                        new_pixels[CONV(j, k, width)].b = p[i][CONV(j, k, width)].b;
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

                        new_pixels[CONV(j,k,width)].r = t_r / ( (2*size+1)*(2*size+1) ) ;
                        new_pixels[CONV(j,k,width)].g = t_g / ( (2*size+1)*(2*size+1) ) ;
                        new_pixels[CONV(j,k,width)].b = t_b / ( (2*size+1)*(2*size+1) ) ;
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

                        diff_r = (new_pixels[CONV(j  ,k  ,width)].r - p[i][CONV(j  ,k  ,width)].r) ;
                        diff_g = (new_pixels[CONV(j  ,k  ,width)].g - p[i][CONV(j  ,k  ,width)].g) ;
                        diff_b = (new_pixels[CONV(j  ,k  ,width)].b - p[i][CONV(j  ,k  ,width)].b) ;

                        if ( diff_r > threshold || -diff_r > threshold 
                                ||
                                    diff_g > threshold || -diff_g > threshold
                                    ||
                                    diff_b > threshold || -diff_b > threshold
                            ) {
                            end = 0 ;
                        }

                        p[i][CONV(j  ,k  ,width)].r = new_pixels[CONV(j  ,k  ,width)].r ;
                        p[i][CONV(j  ,k  ,width)].g = new_pixels[CONV(j  ,k  ,width)].g ;
                        p[i][CONV(j  ,k  ,width)].b = new_pixels[CONV(j  ,k  ,width)].b ;
                    }
                }

            }
            while ( threshold > 0 && !end ) ;

    #if SOBELF_DEBUG
        printf( "BLUR: number of iterations for image %d\n", n_iter ) ;
    #endif

            free (new_pixels) ;
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
            pixel * new_pixels = (pixel *)malloc(width * height * sizeof( pixel ) ) ;


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
                        new_pixels[CONV(j,k,width)].r = p[i][CONV(j,k,width)].r ;
                        new_pixels[CONV(j,k,width)].g = p[i][CONV(j,k,width)].g ;
                        new_pixels[CONV(j,k,width)].b = p[i][CONV(j,k,width)].b ;
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

                        new_pixels[CONV(j,k,width)].r = t_r / ( (2*size+1)*(2*size+1) ) ;
                        new_pixels[CONV(j,k,width)].g = t_g / ( (2*size+1)*(2*size+1) ) ;
                        new_pixels[CONV(j,k,width)].b = t_b / ( (2*size+1)*(2*size+1) ) ;
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
                        new_pixels[CONV(j, k, width)].r = p[i][CONV(j, k, width)].r;
                        new_pixels[CONV(j, k, width)].g = p[i][CONV(j, k, width)].g;
                        new_pixels[CONV(j, k, width)].b = p[i][CONV(j, k, width)].b;
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

                        new_pixels[CONV(j,k,width)].r = t_r / ( (2*size+1)*(2*size+1) ) ;
                        new_pixels[CONV(j,k,width)].g = t_g / ( (2*size+1)*(2*size+1) ) ;
                        new_pixels[CONV(j,k,width)].b = t_b / ( (2*size+1)*(2*size+1) ) ;
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

                        diff_r = (new_pixels[CONV(j  ,k  ,width)].r - p[i][CONV(j  ,k  ,width)].r) ;
                        diff_g = (new_pixels[CONV(j  ,k  ,width)].g - p[i][CONV(j  ,k  ,width)].g) ;
                        diff_b = (new_pixels[CONV(j  ,k  ,width)].b - p[i][CONV(j  ,k  ,width)].b) ;

                        if ( diff_r > threshold || -diff_r > threshold 
                                ||
                                    diff_g > threshold || -diff_g > threshold
                                    ||
                                    diff_b > threshold || -diff_b > threshold
                            ) {
                            end = 0 ;
                        }

                        p[i][CONV(j  ,k  ,width)].r = new_pixels[CONV(j  ,k  ,width)].r ;
                        p[i][CONV(j  ,k  ,width)].g = new_pixels[CONV(j  ,k  ,width)].g ;
                        p[i][CONV(j  ,k  ,width)].b = new_pixels[CONV(j  ,k  ,width)].b ;
                    }
                }

            }
            while ( threshold > 0 && !end ) ;

    #if SOBELF_DEBUG
        printf( "BLUR: number of iterations for image %d\n", n_iter ) ;
    #endif

            free (new_pixels) ;
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
            pixel * new_pixels = (pixel *)malloc(width * height * sizeof( pixel ) ) ;


            /* Perform at least one blur iteration */
            do
            {
                end = 1 ;
                n_iter++ ;


                for(j=0; j<height-1; j++)
                {
                    for(k=0; k<width-1; k++)
                    {
                        new_pixels[CONV(j,k,width)].r = p[i][CONV(j,k,width)].r ;
                        new_pixels[CONV(j,k,width)].g = p[i][CONV(j,k,width)].g ;
                        new_pixels[CONV(j,k,width)].b = p[i][CONV(j,k,width)].b ;
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

                        new_pixels[CONV(j,k,width)].r = t_r / ( (2*size+1)*(2*size+1) ) ;
                        new_pixels[CONV(j,k,width)].g = t_g / ( (2*size+1)*(2*size+1) ) ;
                        new_pixels[CONV(j,k,width)].b = t_b / ( (2*size+1)*(2*size+1) ) ;
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
                        new_pixels[CONV(j, k, width)].r = p[i][CONV(j, k, width)].r;
                        new_pixels[CONV(j, k, width)].g = p[i][CONV(j, k, width)].g;
                        new_pixels[CONV(j, k, width)].b = p[i][CONV(j, k, width)].b;
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

                        new_pixels[CONV(j,k,width)].r = t_r / ( (2*size+1)*(2*size+1) ) ;
                        new_pixels[CONV(j,k,width)].g = t_g / ( (2*size+1)*(2*size+1) ) ;
                        new_pixels[CONV(j,k,width)].b = t_b / ( (2*size+1)*(2*size+1) ) ;
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

                        diff_r = (new_pixels[CONV(j  ,k  ,width)].r - p[i][CONV(j  ,k  ,width)].r) ;
                        diff_g = (new_pixels[CONV(j  ,k  ,width)].g - p[i][CONV(j  ,k  ,width)].g) ;
                        diff_b = (new_pixels[CONV(j  ,k  ,width)].b - p[i][CONV(j  ,k  ,width)].b) ;

                        if ( diff_r > threshold || -diff_r > threshold 
                                ||
                                    diff_g > threshold || -diff_g > threshold
                                    ||
                                    diff_b > threshold || -diff_b > threshold
                            ) {
                            end = 0 ;
                        }

                        p[i][CONV(j  ,k  ,width)].r = new_pixels[CONV(j  ,k  ,width)].r ;
                        p[i][CONV(j  ,k  ,width)].g = new_pixels[CONV(j  ,k  ,width)].g ;
                        p[i][CONV(j  ,k  ,width)].b = new_pixels[CONV(j  ,k  ,width)].b ;
                    }
                }

            }
            while ( threshold > 0 && !end ) ;

    #if SOBELF_DEBUG
        printf( "BLUR: number of iterations for image %d\n", n_iter ) ;
    #endif

            free (new_pixels) ;
        }
    }

}










/////////////// CUDA VERSION ///////////////
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










// void apply_sobel_filter(animated_gif *image) {
//     #pragma omp parallel  
//     {
//         for (int i = 0; i < image->n_images; i++) {
//             const int width = image->width[i];
//             const int height = image->height[i];
//             pixel *pixels = image->p[i];
//             pixel *sobel = malloc(width * height * sizeof(pixel));

//             #pragma omp for collapse(2) schedule(guided) nowait
//             for (int j = 1; j < height - 1; j++) {
//                 #pragma omp simd aligned(pixels, sobel : 64)
//                 for (int k = 1; k < width - 1; k++) {
//                     const int conv_idx = CONV(j, k, width);
                    
                    
//                     const int offsets[] = {
//                         CONV(j-1, k-1, width), CONV(j-1, k, width), CONV(j-1, k+1, width),
//                         CONV(j+1, k-1, width), CONV(j+1, k, width), CONV(j+1, k+1, width),
//                         CONV(j, k-1, width), conv_idx, CONV(j, k+1, width)
//                     };
                    
//                     const int b_no = pixels[offsets[0]].b;
//                     const int b_n  = pixels[offsets[1]].b;
//                     const int b_ne = pixels[offsets[2]].b;
//                     const int b_so = pixels[offsets[3]].b;
//                     const int b_s  = pixels[offsets[4]].b;
//                     const int b_se = pixels[offsets[5]].b;
//                     const int b_o  = pixels[offsets[6]].b;
//                     const int b_e  = pixels[offsets[8]].b;

                    
//                     const float deltaX = -b_no + b_ne - 2*b_o + 2*b_e - b_so + b_se;
//                     const float deltaY = b_se + 2*b_s + b_so - b_ne - 2*b_n - b_no;
//                     const float val = sqrtf(deltaX*deltaX + deltaY*deltaY) / 4.0f;

                    
//                     const unsigned char result = (val > 50.0f) ? 255 : 0;
//                     sobel[conv_idx] = (pixel){result, result, result};
//                 }
//             }

//             #pragma omp barrier

//             #pragma omp for simd collapse(2) schedule(static) aligned(pixels, sobel : 64)
//             for (int j = 1; j < height - 1; j++) {
//                 for (int k = 1; k < width - 1; k++) {
//                     pixels[CONV(j, k, width)] = sobel[CONV(j, k, width)];
//                 }
//             }

//             free(sobel);
//         }
//     }
// }










///////// Working version /////////
/*/*
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
    
    // Variables for OpenMP/GPU usage tracking - declare at top level for proper scope
    char * Using_OpenMP = NULL;
    char * Using_GPU = NULL;
    int parallelization_type = 0;
    int nb_images = 0;
    int nb_pixels = 0;

    /* Initialize MPI */
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* Check command-line arguments */
    if ( argc < 3 )
    {
        if (rank == 0) {
            fprintf( stderr, "Usage: %s input.gif output.gif \n", argv[0] ) ;
        }
        MPI_Finalize();
        return 1 ;
    }

    input_filename = argv[1] ;
    output_filename = argv[2] ;

    /* Only the root process handles file I/O */
    if (rank == 0) {
        duration_file = fopen("durations_para.csv", "a");
        if (duration_file == NULL) {
            perror("Erreur lors de l'ouverture du fichier");
            MPI_Abort(MPI_COMM_WORLD, 1);
            return 1;
        }

        /* Check if the file is empty to write the header */
        fseek(duration_file, 0, SEEK_END);
        if (ftell(duration_file) == 0) {
            fprintf(duration_file, "Filename,Using_OpenMP,Using_GPU,MPI_Processes,Number Images,Number Pixels,Import Duration,Gray Filter Duration,Blur Filter Duration,Sobel Filter Duration,Export Duration\n");
        }
        fseek(duration_file, 0, SEEK_END);

        /* IMPORT Timer start */
        gettimeofday(&t1, NULL);

        /* Load file and store the pixels in array */
        image = load_pixels( input_filename ) ;
        if ( image == NULL ) { 
            MPI_Abort(MPI_COMM_WORLD, 1);
            return 1; 
        }

        /* IMPORT Timer stop */
        gettimeofday(&t2, NULL);

        import_duration = (t2.tv_sec - t1.tv_sec) + ((t2.tv_usec - t1.tv_usec) / 1e6);

#if PRINT_TIME
        printf( "GIF loaded from file %s with %d image(s) in %lf s\n", 
                input_filename, image->n_images, import_duration ) ;
#endif

        //// Determine parallelization type for OpenMP
        if (image->n_images >= 16) {
            parallelization_type = PARALLELIZE_IMAGES;
            Using_OpenMP = "Using_OpenMP on images";
        } else if (image->width[0] * image->height[0] >= 100000) {
            parallelization_type = PARALLELIZE_PIXELS;
            Using_OpenMP = "Using_OpenMP on pixels";
        } else {
            parallelization_type = NO_PARALLELIZATION;
            Using_OpenMP = "No";
        }

        nb_images = image->n_images;
        nb_pixels = image->width[0] * image->height[0];

        /* Gray Filter Timer start */
        gettimeofday(&t1, NULL);
        apply_gray_filter( image, parallelization_type) ;
        gettimeofday(&t2, NULL);
        gray_duration = (t2.tv_sec - t1.tv_sec) + ((t2.tv_usec - t1.tv_usec) / 1e6);

#if PRINT_TIME
        printf( "Gray filter done in %lf s\n", gray_duration );
#endif

        /* Blur Filter Timer start */
        gettimeofday(&t1, NULL);
        if (nb_images * nb_pixels >= 5000000) {
            apply_blur_filter_multi_gpu(image, 5, 20);
            Using_GPU = "Yes";
        } else {
            apply_blur_filter( image, 5, 20, parallelization_type) ;
            Using_GPU = "No";
        }
        gettimeofday(&t2, NULL);
        blur_duration = (t2.tv_sec - t1.tv_sec) + ((t2.tv_usec - t1.tv_usec) / 1e6);

#if PRINT_TIME
        printf( "Blur filter done in %lf s\n", blur_duration );
#endif
    }

    // ----- MPI SOBEL FILTER SECTION -----
    
    // Broadcast number of images to all processes
    int n_images;
    if (rank == 0) n_images = image->n_images;
    MPI_Bcast(&n_images, 1, MPI_INT, 0, MPI_COMM_WORLD);

    // Calculate images per process
    int images_per_proc = n_images / size;
    int remainder = n_images % size;
    int start = rank * images_per_proc + ((rank < remainder) ? rank : remainder);
    int my_count = images_per_proc + ((rank < remainder) ? 1 : 0);
    if (start >= n_images) my_count = 0;

    // Create MPI datatype for pixel
    MPI_Datatype pixel_type;
    MPI_Type_contiguous(3, MPI_INT, &pixel_type);
    MPI_Type_commit(&pixel_type);

    int *my_widths = NULL, *my_heights = NULL;
    pixel **my_pixels = NULL;

    // Distribute the data
    if (rank == 0) {
        for (int p = 1; p < size; p++) {
            int p_start = p * images_per_proc + ((p < remainder) ? p : remainder);
            int p_count = images_per_proc + ((p < remainder) ? 1 : 0);
            if (p_start >= n_images) continue;

            for (int i = 0; i < p_count; i++) {
                int idx = p_start + i;
                int w = image->width[idx], h = image->height[idx];
                MPI_Send(&w, 1, MPI_INT, p, 0, MPI_COMM_WORLD);
                MPI_Send(&h, 1, MPI_INT, p, 0, MPI_COMM_WORLD);
                MPI_Send(image->p[idx], w*h, pixel_type, p, 0, MPI_COMM_WORLD);
            }
        }

        // Use proper CUDA-compatible casting for malloc
        my_widths = (int*)malloc(my_count * sizeof(int));
        my_heights = (int*)malloc(my_count * sizeof(int));
        my_pixels = (pixel**)malloc(my_count * sizeof(pixel*));
        
        for (int i = 0; i < my_count; i++) {
            int idx = start + i;
            my_widths[i] = image->width[idx];
            my_heights[i] = image->height[idx];
            my_pixels[i] = image->p[idx];
        }
    } else if (my_count > 0) {
        // Use proper CUDA-compatible casting for malloc
        my_widths = (int*)malloc(my_count * sizeof(int));
        my_heights = (int*)malloc(my_count * sizeof(int));
        my_pixels = (pixel**)malloc(my_count * sizeof(pixel*));
        
        for (int i = 0; i < my_count; i++) {
            MPI_Recv(&my_widths[i], 1, MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            MPI_Recv(&my_heights[i], 1, MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            int size = my_widths[i] * my_heights[i];
            my_pixels[i] = (pixel*)malloc(size * sizeof(pixel));
            MPI_Recv(my_pixels[i], size, pixel_type, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        }
    }

    // Store pixel dimensions for CSV output
    int pixel_count = 0;
    if (rank == 0 && my_count > 0) {
        pixel_count = my_widths[0] * my_heights[0];
    }
    
    // Synchronize all processes before starting Sobel filter
    MPI_Barrier(MPI_COMM_WORLD);
    
    // Start timer on rank 0
    if (rank == 0) {
        gettimeofday(&t1, NULL);
    }
    
    // Each process applies the Sobel filter to its assigned images
    for (int i = 0; i < my_count; i++) {
        animated_gif tmp = {
            .n_images = 1,
            .width = &my_widths[i],
            .height = &my_heights[i],
            .p = &my_pixels[i]
        };
        apply_sobel_filter(&tmp, NO_PARALLELIZATION);  // No OpenMP within MPI processes
    }
    
    // Synchronize all processes after completion
    MPI_Barrier(MPI_COMM_WORLD);
    
    // Stop timer on rank 0
    if (rank == 0) {
        gettimeofday(&t2, NULL);
        sobel_duration = (t2.tv_sec - t1.tv_sec) + ((t2.tv_usec - t1.tv_usec) / 1e6);
#if PRINT_TIME
        printf("Sobel filter completed in %lf s\n", sobel_duration);
#endif
    }

    // Gather processed data back to rank 0
    if (rank != 0 && my_count > 0) {
        for (int i = 0; i < my_count; i++) {
            MPI_Send(my_pixels[i], my_widths[i]*my_heights[i], pixel_type, 0, 0, MPI_COMM_WORLD);
        }
    } else if (rank == 0) {
        for (int p = 1; p < size; p++) {
            int p_start = p * images_per_proc + ((p < remainder) ? p : remainder);
            int p_count = images_per_proc + ((p < remainder) ? 1 : 0);
            if (p_start >= n_images) continue;

            for (int i = 0; i < p_count; i++) {
                int idx = p_start + i;
                int w = image->width[idx], h = image->height[idx];
                MPI_Recv(image->p[idx], w*h, pixel_type, p, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            }
        }
    }

    // Cleanup MPI resources
    MPI_Type_free(&pixel_type);
    if (rank != 0) {
        for (int i = 0; i < my_count; i++) {
            free(my_pixels[i]);
        }
        free(my_pixels);
        free(my_widths);
        free(my_heights);
    }

    // Only the root process continues with the rest of the sequential code
    if (rank == 0) {
        /* Calculate total filter duration */
        filter_duration = gray_duration + blur_duration + sobel_duration;
        printf("Total filter time: %lf s\n", filter_duration);

        /* EXPORT Timer start */
        gettimeofday(&t1, NULL);

        /* Store file from array of pixels to GIF file */
        if (!store_pixels(output_filename, image, NO_PARALLELIZATION)) {
            MPI_Finalize();
            return 1;
        }
 
        /* EXPORT Timer stop */
        gettimeofday(&t2, NULL);

        export_duration = (t2.tv_sec - t1.tv_sec) + ((t2.tv_usec - t1.tv_usec) / 1e6);

#if PRINT_TIME
        printf("Export done in %lf s in file %s\n", export_duration, output_filename);
#endif

        /* Write durations to file with MPI process count */
        fprintf(duration_file, "%s,%s,%s,%d,%d,%d,%lf,%lf,%lf,%lf,%lf\n", 
                input_filename, Using_OpenMP, Using_GPU, size, n_images, pixel_count, 
                import_duration, gray_duration, blur_duration, sobel_duration, export_duration);

        /* Close the file */
        fclose(duration_file);
        
        /* Free the image data */
        free(image);
    }

    MPI_Finalize();
    return 0;
}




