const functions = require("firebase-functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const request = require("request");

// TODO: Paste your Prerender.io token here
const PRERENDER_TOKEN = "JobBZ4J2lZ58Bi83Q4ve";

// A list of common bot user agents to prerender
const BOT_AGENTS = [
  "googlebot",
  "bingbot",
  "yahoo! slurp",
  "duckduckbot",
  "baiduspider",
  "yandexbot",
  "sogou",
  "twitterbot",
  "facebookexternalhit",
  "linkedinbot",
  "pinterest",
  "slackbot",
  "discordbot",
  "google-adsense",
];

exports.render = functions.https.onRequest((req, res) => {
  const userAgent = (req.headers["user-agent"] || "").toLowerCase();
  const isBot = BOT_AGENTS.some(agent => userAgent.includes(agent));

  // Get the full URL of the incoming request
  const siteUrl = `https://${req.hostname}`;
  const originalUrl = `${siteUrl}${req.originalUrl}`;

  // If the visitor is a bot, proxy the request to Prerender.io
  if (isBot) {
    console.log(`[BOT] Prerendering URL: ${originalUrl}`);

    const prerenderUrl = `https://service.prerender.io/${originalUrl}`;
    const proxyRequest = request({
      url: prerenderUrl,
      headers: {
        "X-Prerender-Token": PRERENDER_TOKEN,
      },
    });

    // Send the request to Prerender and pipe the response back to the bot
    req.pipe(proxyRequest).pipe(res);

  } else {
    // If the visitor is a user, serve the Flutter app's index.html
    console.log(`[USER] Serving app for URL: ${originalUrl}`);

    // We fetch the index.html from our own hosting to serve it.
    // This avoids a redirect loop.
    request(`${siteUrl}/index.html`).pipe(res);
  }
});

// ---------------------------------------------------------------------------
// Groq API proxy — Gen 2 callable function with Secret Manager binding.
//
// The developer Groq API key is stored in Firebase Secret Manager.
// Set via: firebase functions:secrets:set DEVELOPER_GROQ_API_KEY
//
// The function accepts a single payload with a `type` discriminator:
//   • type = "chat"   → plain text / chat completions
//   • type = "vision" → multimodal (image + text) completions
// ---------------------------------------------------------------------------
const GROQ_CHAT_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";

// Declare the secret using the firebase-functions/params API (required for v6+).
const developerGroqApiKey = defineSecret("DEVELOPER_GROQ_API_KEY");

exports.groqProxy = onCall(
  { secrets: [developerGroqApiKey] },
  async (callRequest) => {
    const apiKey = developerGroqApiKey.value();
    if (!apiKey) {
      throw new HttpsError(
        "unavailable",
        "Developer Groq API key is not configured."
      );
    }

    const { type, model, messages, systemPrompt, prompt, base64Image, mimeType } =
      callRequest.data || {};

    if (!model) {
      throw new HttpsError("invalid-argument", "Missing required field: model");
    }

    let requestBody;
    if (type === "vision") {
      if (!prompt || !base64Image || !mimeType) {
        throw new HttpsError(
          "invalid-argument",
          "Vision requests require: prompt, base64Image, mimeType"
        );
      }
      requestBody = {
        model,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: prompt },
              {
                type: "image_url",
                image_url: { url: `data:${mimeType};base64,${base64Image}` },
              },
            ],
          },
        ],
      };
    } else {
      // Default: chat completions
      if (!messages || !Array.isArray(messages)) {
        throw new HttpsError(
          "invalid-argument",
          "Chat requests require a messages array"
        );
      }
      requestBody = {
        model,
        messages: systemPrompt
          ? [{ role: "system", content: systemPrompt }, ...messages]
          : messages,
      };
    }

    let response;
    try {
      response = await fetch(GROQ_CHAT_ENDPOINT, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(requestBody),
      });
    } catch (networkError) {
      throw new HttpsError(
        "unavailable",
        `Network error: ${networkError.message}`
      );
    }

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[groqProxy] Groq API error ${response.status}: ${errorText}`);
      throw new HttpsError(
        "internal",
        `Groq API error (${response.status})`
      );
    }

    const responseData = await response.json();
    const choices = responseData.choices;
    if (!choices || choices.length === 0) {
      return { content: null };
    }
    const content = choices[0]?.message?.content ?? null;
    return { content };
  }
);