import { App } from './app';
import { loadSave } from './save';
import { sdk } from './sdk';
import { Stage } from './view/stage';
import { GameView } from './view/gameView';

async function boot(): Promise<void> {
  const canvas = document.getElementById('stage') as HTMLCanvasElement;
  const stage = new Stage(canvas);
  let app: App | null = null;
  const view = new GameView(stage, (info) => app?.press(info));

  // Paint the table straight away so the first frame is never empty.
  stage.resize();
  stage.render();
  sdk.firstFrameReady();

  const params = new URLSearchParams(location.search);
  const save = await loadSave();
  if (params.get('tut') === '0') save.tutorialDone = true;
  app = new App(view, save);
  const forced = params.has('p') ? Number(params.get('p')) : undefined;
  app.start(forced);
  if (params.get('done') === '1') app.debugFill(0);
  if (params.get('almost') === '1') app.debugFill(1);

  window.addEventListener('resize', () => stage.resize());
  sdk.onPause(() => app!.pause());
  sdk.onResume(() => app!.resume());
  const loop = (ts: number) => {
    app!.frame(ts);
    requestAnimationFrame(loop);
  };
  requestAnimationFrame(loop);
  sdk.gameReady();
  (window as unknown as { __game?: App }).__game = app;
}

void boot();
