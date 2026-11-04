# Proof of Concept: "Layer of stacks" - Group Rendering and Painting 

This is an experiment and a try to create a base for Rendering and Drawing of Objects like Rectangle or Text in Nim.

The idea is to use Group Rendering for areas on a screen to reduce rendering and upload to the GPU.

There is no roadmap and no plan for development. It is a learning project to understand the complexity of an Retained UI Framework.

## Tier 1 - Some aspects for Rendering/Drawing:

- [x] Use only primitive GPU-Objects (traingles) for Rectangle, Circle
- [ ] Text/Fonts rendering of .ttf or .otf fonts - there are 3 ways to bring text to the GPU and on the screen.
  - [-] Texture-Rendering on CPU and uploading each word as Texture(Image) to GPU - Max Texture-Buffer GL=32, GLES=16 for one upload to GPU. GUI wirh lot of text or a GUI with an Table Widget are expected to be less performant and to consume more CPU/GPU power. Cashing of Images should use more Memory than only coordinates.
  - [X] Glyph-Atlas-Rendering: Glyph rendering from Glyph-Atlas(Texture) on GPU - no texturebuffer limit!
  - [ ] Glyph-Slug-Rendering: Glyph rendering as primitive GPU-Objects based on the Slug algorithm, originally developed by Eric Lengyel https://github.com/EricLengyel/Slug
- [x] Transfer as much work as possible from CPU to GPU
- [x] Low CPU and GPU power consuming on runtime 
  - [x] Rectangle, Circle
  - [x] Glyph-Atlas-Rendering: Initial upload of Glyph-Atlas(Texture) to GPU. No further Texture uploads, only coordinates are copied to GPU. Simple OpenGL shaders.
  - [ ] Glyph-Slug-Rendering:
- [x] Small size of static compiled binary
- [x] Antialiazing of DrawerObjects without hardware antialiazing (MSAA = MultiSampling Anti-Aliasing)
- [x] Reduce single uploads from CPU to GPU. (Group Rendering/Drawing)
- [x] Simple and readable design and coding (no templates, no macros, no DSL)
- [ ] Drawing of areas/groups. Caching -> ? move to Tier 2
- [ ] Event Loop on main thread / Drawing on separate thread
- [ ] Stress test with many objects
- [ ] Comparison with other lightweight vector graphics engines
  - [ ] ThorVG https://github.com/thorvg/thorvg

Some ideas come from an earlier experiment about "Group Rendering":
https://github.com/fyne-io/fyne/issues/3412#issuecomment-1646863204

### Next steps for Tier 1
- [ ] Merge `group_rectangle` shaders with `group_glyph_atlas` shaders. It should be possible because Glyph-Atlas-Rendering has no texture buffer limit (no single textures are uploaded to GPU). Both shaders are simple and lightweight.  
- [ ] Implement areas/grouping for drawing.
- [ ] Reorganize coding (Design/Packages/Naming):
  - [ ] Analyse code-design for `relbase`. (eg. `relays` or `silky`)
  - [ ] Define a clear split between Drawing (Tier 1: DrawObjects, Shapes, ...) and Rendering (Tier 2: Widgets, Components, ...). 
  - [ ] Split coding into Packages/Repositories. 

If the performance tests are successful Tier 2 (in another package) could follow.

## Tier 2 - Some ideas for Retained-Mode UI FW:

- [ ] Imperative design
- [ ] Events with callbacks
- [ ] Simple layout system. (only columns and rows)
- [ ] Bare minimum Widgets/Controls
- [ ] Check, if "Relays" fit for Retained-Mode (https://github.com/nim-lang/uirelays)
- [ ] Name for Tier 2?: `relbox` `relface`


## Example
`src/main.nim` is an example or a test file.
- Put your font (ttf, otf) into dir `src\data`.
- Change in `gl.nim` the font name in `proc init*(self: Painter)` to your font in `src\data`. After starting the example app the builder creates a file `glyph_atlas.png` into dir `src\dist`, which is uploaded once to GPU and reused for redrawing. <br>
<br>
- Resizing window re-draws the screen (no re-rendering). See `src/gl.nim`  `proc renderTree(...)`
- Mouse-Click prints (`echo`) the coordinates



![Example_Windy](Example_Windy.png)

## Installation
`nimble install https://github.com/treeform/silky@#master` <br>
From Framework `silky` are two files used for Glyph-Atlas-Generation and Atlas-Texture handling. <br>
https://github.com/treeform/silky/blob/master/src/silky/atlas.nim <br>
https://github.com/treeform/silky/blob/master/src/silky/allocator.nim <br>

Windy <br>
`windy` is installed as dependency of `silky` <br>
`nim.exe c -d:WindyGl -d:release .\src\main.nim` <br>
GLFW <br>
`nimble install https://github.com/RowDaBoat/nglfw` <br> 
`nim.exe c -d:GlfwGL -d:release .\src\main.nim` <br>

