// Supabase Edge Function skeleton.
// Validate authenticated teacher ownership before generating a short-lived R2 upload URL.
// Keep R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY and bucket configuration in function secrets.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  return new Response(
    JSON.stringify({ error: "Configure R2 presigned PUT signing in this Edge Function before deployment." }),
    { status: 501, headers: { "content-type": "application/json" } },
  );
});
