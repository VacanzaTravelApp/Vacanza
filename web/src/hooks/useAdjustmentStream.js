import { useEffect, useRef } from "react";
import { auth } from "../firebase";

/**
 * FReq5 — Listens for server-sent `route_updated` events from the backend.
 *
 * Uses fetch + ReadableStream instead of EventSource because EventSource does
 * not support custom request headers (Authorization: Bearer <token>).
 *
 * Reconnects automatically after 5 seconds on unexpected disconnect.
 * Cleans up on unmount.
 *
 * @param {(data: object) => void} onRouteUpdated  Called with parsed JSON payload on each event.
 */
export function useAdjustmentStream(onRouteUpdated) {
  // Keep callback in a ref so reconnects don't need re-registration
  const callbackRef = useRef(onRouteUpdated);
  callbackRef.current = onRouteUpdated;

  useEffect(() => {
    let active = true;
    let abortController = null;

    const connect = async () => {
      try {
        const user = auth.currentUser;
        if (!user || !active) return;

        const token = await user.getIdToken();
        if (!active) return;

        abortController = new AbortController();

        const res = await fetch("/api/routes/adjustment-stream", {
          headers: { Authorization: `Bearer ${token}` },
          signal: abortController.signal,
        });

        if (!res.ok || !res.body) {
          // Non-2xx or no body — don't retry aggressively
          return;
        }

        const reader = res.body.getReader();
        const decoder = new TextDecoder();
        let buf = "";

        while (active) {
          const { done, value } = await reader.read();
          if (done) break;

          buf += decoder.decode(value, { stream: true });
          const lines = buf.split("\n");
          buf = lines.pop(); // keep incomplete last line

          let eventName = null;
          let data = null;

          for (const line of lines) {
            if (line.startsWith("event:")) {
              eventName = line.slice(6).trim();
            } else if (line.startsWith("data:")) {
              data = line.slice(5).trim();
            } else if (line === "" && data != null) {
              if (eventName === "route_updated") {
                try {
                  callbackRef.current(JSON.parse(data));
                } catch {
                  // malformed JSON — skip
                }
              }
              eventName = null;
              data = null;
            }
          }
        }
      } catch (err) {
        if (err.name === "AbortError") return;
        // Network error or timeout — retry after 5 s
        if (active) {
          setTimeout(() => { if (active) connect(); }, 5000);
        }
      }
    };

    connect();

    return () => {
      active = false;
      abortController?.abort();
    };
  }, []); // intentionally empty — callback is kept fresh via ref
}
