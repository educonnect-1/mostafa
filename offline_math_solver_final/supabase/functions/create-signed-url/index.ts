// Supabase Edge Function skeleton.
// Put Cloudflare R2 credentials in Edge Function secrets, never in Flutter.
// Implement authorization against the lesson's course enrollment/preview status,
// then sign the R2 object for a short playback window.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  return new Response(
    JSON.stringify({ error: "Configure R2 signing in this Edge Function before deployment." }),
    { status: 501, headers: { "content-type": "application/json" } },
  );
});
