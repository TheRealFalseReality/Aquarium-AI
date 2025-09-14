const functions = require("firebase-functions");
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