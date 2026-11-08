// Drops Umami events with the fake aocr.org referrer a bot sends, and passes everything else on to Umami.
function send(r) {
    let referrer;
    try {
        referrer = JSON.parse(r.requestText).payload.referrer;
    } catch (e) {}

    if (typeof referrer === "string" && referrer.includes("aocr.org")) {
        r.return(204);
        return;
    }

    r.internalRedirect("@umami_send");
}

export default { send };
