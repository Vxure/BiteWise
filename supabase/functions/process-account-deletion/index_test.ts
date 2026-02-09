import { assertEquals } from "https://deno.land/std@0.224.0/testing/asserts.ts";

Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "service_role_test");

const { handler } = await import("./index.ts?test=" + Date.now());

Deno.test("rejects missing Authorization header", async () => {
  const res = await handler(
    new Request("https://example.test/process-account-deletion", {
      method: "POST",
      body: "{}",
    })
  );

  assertEquals(res.status, 401);
});

Deno.test("rejects invalid Authorization header", async () => {
  const res = await handler(
    new Request("https://example.test/process-account-deletion", {
      method: "POST",
      headers: { authorization: "Bearer wrong" },
      body: "{}",
    })
  );

  assertEquals(res.status, 401);
});
