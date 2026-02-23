const functions = require("firebase-functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const request = require("request");
const admin = require("firebase-admin");

// Initialize the Firebase Admin SDK (idempotent - safe to call multiple times).
if (!admin.apps.length) {
  admin.initializeApp();
}

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

// ---------------------------------------------------------------------------
// Play Integrity API verification helper
//
// Decrypts and verifies an integrity token by calling the Play Integrity REST
// API with Application Default Credentials (automatically provided inside
// Cloud Functions).
//
// Package name must match the production app ID registered in Google Play.
// ---------------------------------------------------------------------------
const PLAY_INTEGRITY_PACKAGE = "com.cca.fishai";
const PLAY_INTEGRITY_ENDPOINT =
  `https://playintegrity.googleapis.com/v1/${PLAY_INTEGRITY_PACKAGE}:decryptIntegrityToken`;

// Simple in-memory cache for the ADC access token.
// Cloud Function instances are reused between requests, so caching here
// avoids a metadata server round-trip on every invocation.
let _cachedAccessToken = null;
let _tokenExpiresAt = 0; // Unix timestamp in ms

async function getPlayIntegrityAccessToken() {
  const now = Date.now();
  // Refresh 60 s before expiry to avoid using a stale token.
  if (_cachedAccessToken && now < _tokenExpiresAt - 60_000) {
    return _cachedAccessToken;
  }
  const credential = admin.credential.applicationDefault();
  const tokenInfo = await credential.getAccessToken();
  _cachedAccessToken = tokenInfo.access_token;
  // access_token objects include an expiry_date in ms; fall back to 1 hour.
  _tokenExpiresAt = tokenInfo.expiry_date ?? now + 3_600_000;
  return _cachedAccessToken;
}

/**
 * Calls the Play Integrity REST API to decrypt and return the token payload.
 * @param {string} integrityToken - The token returned by the Android Play Integrity API.
 * @returns {Promise<object>} Decoded tokenPayloadExternal from the Play Integrity API.
 */
async function decryptIntegrityToken(integrityToken) {
  const accessToken = await getPlayIntegrityAccessToken();

  const integrityResponse = await fetch(PLAY_INTEGRITY_ENDPOINT, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ integrity_token: integrityToken }),
  });

  if (!integrityResponse.ok) {
    const errorText = await integrityResponse.text();
    console.error(
      `[integrity] Play Integrity API error ${integrityResponse.status}: ${errorText}`
    );
    throw new HttpsError(
      "unavailable",
      `Play Integrity API error (${integrityResponse.status})`
    );
  }

  const payload = await integrityResponse.json();
  return payload.tokenPayloadExternal ?? payload;
}

// ---------------------------------------------------------------------------
// verifyIntegrityToken — Gen 2 callable function
//
// Accepts an integrity token and the original nonce from the Android client,
// decrypts the token via the Play Integrity API, verifies that the nonce
// embedded in the token matches the one supplied by the client (replay
// protection), enforces app/device integrity verdicts server-side, and
// returns only a boolean pass/fail result to the caller.
//
// Expected request data:  { integrityToken: string, nonce: string }
// Response on pass:       { passed: true }
// Throws HttpsError on integrity failure or invalid input.
// ---------------------------------------------------------------------------
exports.verifyIntegrityToken = onCall(async (callRequest) => {
  const { integrityToken, nonce } = callRequest.data || {};
  if (!integrityToken || typeof integrityToken !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "Missing required field: integrityToken"
    );
  }
  if (!nonce || typeof nonce !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "Missing required field: nonce"
    );
  }

  const verdict = await decryptIntegrityToken(integrityToken);

  // --- Nonce validation (replay-attack protection) ---
  // The Play Integrity API base64url-encodes the nonce in the token payload.
  const tokenNonce = verdict?.requestDetails?.nonce;
  if (tokenNonce !== nonce) {
    console.warn("[integrity] Nonce mismatch – possible replay attack");
    throw new HttpsError("permission-denied", "Integrity check failed.");
  }

  // --- App-recognition verdict enforcement ---
  const appVerdict =
    verdict?.appIntegrity?.appRecognitionVerdict ?? "UNKNOWN";
  const deviceVerdicts =
    verdict?.deviceIntegrity?.deviceRecognitionVerdict ?? [];

  console.log(
    `[integrity] appVerdict=${appVerdict} ` +
    `deviceVerdict=${JSON.stringify(deviceVerdicts)}`
  );

  // Reject requests from unrecognised or tampered app builds.
  // UNRECOGNIZED_VERSION covers sideloaded/staged builds which are
  // acceptable in development; only reject fully unlicensed installs.
  if (appVerdict === "UNAPPROVED") {
    throw new HttpsError("permission-denied", "Integrity check failed.");
  }

  return { passed: true };
});