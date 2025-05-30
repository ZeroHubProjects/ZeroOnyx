/* eslint-disable no-undef */
/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

// Themes
import "./styles/main.scss";
import "./styles/themes/light.scss";

import { perf } from "common/perf";
import { combineReducers } from "common/redux";
import { setupHotReloading } from "tgui-dev-server/link/client";
import { setupGlobalEvents } from "tgui/events";
import { captureExternalLinks } from "tgui/links";
import { createRenderer } from "tgui/renderer";
import { configureStore, StoreProvider } from "tgui/store";
import { audioMiddleware, audioReducer } from "./audio";
import { chatMiddleware, chatReducer } from "./chat";
import { gameMiddleware, gameReducer } from "./game";
import { setupPanelFocusHacks } from "./panelFocus";
import { settingsMiddleware, settingsReducer } from "./settings";
import { telemetryMiddleware } from "./telemetry";
import { spellCheckerReducer } from "./spellchecker/reducer";
import { spellCheckerMiddleware } from "./spellchecker/middleware";

perf.mark("inception", window.performance?.timing?.navigationStart);
perf.mark("init");

const store = configureStore({
  reducer: combineReducers({
    audio: audioReducer,
    chat: chatReducer,
    game: gameReducer,
    settings: settingsReducer,
    spellChecker: spellCheckerReducer,
  }),
  middleware: {
    pre: [
      chatMiddleware,
      telemetryMiddleware,
      settingsMiddleware,
      audioMiddleware,
      gameMiddleware,
      spellCheckerMiddleware,
    ],
  },
});

const renderApp = createRenderer(() => {
  const { Panel } = require("./Panel");
  return (
    <StoreProvider store={store}>
      <Panel />
    </StoreProvider>
  );
});

const setupApp = () => {
  // Delay setup
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", setupApp);
    return;
  }

  setupGlobalEvents({
    ignoreWindowFocus: true,
  });
  setupPanelFocusHacks();
  captureExternalLinks();

  // Re-render UI on store updates
  store.subscribe(renderApp);

  Byond.subscribe((type, payload) => store.dispatch({ type, payload }));

  // Unhide the panel
  Byond.winset('output_container', {
    left: 'tgui_chat',
  });

  // Resize the panel to match the non-browser output
  Byond.winget("output").then((output) => {
    Byond.winset("tgchat_output", {
      size: output.size,
    });
  });

  // Enable hot module reloading
  if (module.hot) {
    setupHotReloading();
    module.hot.accept(
      [
        "./audio",
        "./chat",
        "./game",
        "./Notifications",
        "./Panel",
        "./settings",
        "./telemetry",
        "./spellchecker",
      ],
      () => {
        renderApp();
      }
    );
  }
};

setupApp();
