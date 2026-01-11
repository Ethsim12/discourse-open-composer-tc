import { apiInitializer } from "discourse/lib/api";
import Composer from "discourse/models/composer";

/**
 * Payload format in localStorage (JSON string):
 * {
 *   "mode": "new_topic" | "reply",
 *   "categoryId": 19,
 *   "topicId": 123,          // required for reply
 *   "title": "Optional title",
 *   "body": "Optional body"
 * }
 */

function safeJsonParse(str) {
  try {
    return JSON.parse(str);
  } catch {
    return null;
  }
}

function pathMatchesAny(url, prefixes) {
  // url passed by api.onPageChange is typically a path like "/latest" (no origin)
  return (prefixes || []).some((p) => {
    if (!p) return false;
    return url.startsWith(p);
  });
}

function getComposerController(api) {
  // Theme/plugin API gives access to the Ember container.
  // This tends to be the most stable way to access the composer “open” API.
  return api.container.lookup("controller:composer");
}

function openNewTopic(composerController, { categoryId, title, body }) {
  composerController.open({
    action: Composer.CREATE_TOPIC,
    categoryId,
    topicTitle: title || "",
    topicBody: body || "",
  });
}

function openReply(composerController, { topicId, body }) {
  if (!topicId) return false;

  composerController.open({
    action: Composer.REPLY,
    topicId,
    topicBody: body || "",
  });

  return true;
}

export default apiInitializer((api) => {
  api.onPageChange((url) => {
    if (!settings.open_composer_enabled) return;

    const storageKey = settings.open_composer_storage_key || "open_composer_once";

    // 1) Try localStorage payload first (one-shot signal across redirects)
    const raw = window.localStorage.getItem(storageKey);
    const payload = raw ? safeJsonParse(raw) : null;

    // 2) Otherwise optionally use defaults on certain paths
    const useDefaults =
      !payload &&
      settings.open_composer_use_defaults_on_paths &&
      pathMatchesAny(url, settings.open_composer_paths);

    if (!payload && !useDefaults) return;

    const composerController = getComposerController(api);
    if (!composerController) return;

    // Ensure it only fires once
    window.localStorage.removeItem(storageKey);

    const mode = (payload?.mode || settings.open_composer_default_mode || "new_topic").toLowerCase();

    if (mode === "reply") {
      const ok = openReply(composerController, {
        topicId: payload?.topicId || Number(settings.open_composer_default_topic_id) || 0,
        body: payload?.body || settings.open_composer_default_body,
      });

      if (!ok) {
        // If reply is misconfigured, fall back to new topic instead of doing nothing
        openNewTopic(composerController, {
          categoryId: payload?.categoryId || Number(settings.open_composer_default_category_id) || null,
          title: payload?.title || settings.open_composer_default_title,
          body: payload?.body || settings.open_composer_default_body,
        });
      }

      return;
    }

    // new_topic
    openNewTopic(composerController, {
      categoryId: payload?.categoryId || Number(settings.open_composer_default_category_id) || null,
      title: payload?.title || settings.open_composer_default_title,
      body: payload?.body || settings.open_composer_default_body,
    });
  });
});
