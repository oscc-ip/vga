#include <SDL2/SDL.h>
#include <stdio.h>

#define WIDTH 640
#define DEPTH 480

int main() {

  SDL_Window *window = nullptr;
  SDL_Renderer *renderer = nullptr;

  SDL_Init(SDL_INIT_VIDEO);
  // used for high dpi screen
  SDL_CreateWindowAndRenderer(640 * 4, 480 * 4, 0, &window, &renderer);
  SDL_RenderSetScale(renderer, 4, 4);
  // SDL_CreateWindowAndRenderer(640, 480, 0, &window, &renderer);
  // // SDL_RenderSetScale(renderer, 4, 4); // used for high dpi screen

  SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); // set renderer color
  SDL_RenderClear(renderer); // clear the screen with the renderer color

  // SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255); // choose another
  // color: white SDL_RenderDrawPoint(renderer, 640 / 2,
  //                     480 / 2); // draw a pixel use the renderer color
  // SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255); // choose another color:
  // red SDL_RenderDrawPoint(renderer, 0, 0); // draw a pixel use the renderer
  // color
  // for (int i = 0; i < WIDTH; i++) {
  //   for (int j = 0; j < DEPTH; j++) {
  //     SDL_SetRenderDrawColor(renderer, i % 255, j % 255, i % 255,
  //                            255);         // choose another color
  //     SDL_RenderDrawPoint(renderer, i, j); // draw a pixel use the renderer
  //   }
  // }
  SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255); // choose another color
  SDL_RenderDrawPoint(renderer, 0, 0); // draw a pixel use the renderer
  SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255); // choose another color
  SDL_RenderDrawPoint(renderer, 640/2, 480/2); // draw a pixel use the renderer
  SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255); // choose another color
  SDL_RenderDrawPoint(renderer, 640-1, 480-1); // draw a pixel use the renderer

  SDL_RenderPresent(renderer);
  SDL_Delay(3000);

  return 0;
}
