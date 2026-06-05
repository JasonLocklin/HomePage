<?xml version="1.0" encoding="utf-8"?>
<!--
  feed.xsl — Atom feed stylesheet for browser viewing
  Injected into all atom.xml files at build time (see justfile build-web recipe).
  Browsers that support XSLT (Firefox, Safari) render this instead of raw XML.
-->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:atom="http://www.w3.org/2005/Atom"
  exclude-result-prefixes="atom">

  <xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes"/>

  <xsl:template match="/">
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title><xsl:value-of select="/atom:feed/atom:title"/> — Feed</title>
        <style>
          :root { --bg: #211f1a; --fg: #f0f0f0; --orange: rgb(255,168,106); --dim: #909090; }
          * { box-sizing: border-box; margin: 0; padding: 0; }
          body {
            background: var(--bg);
            color: var(--fg);
            font-family: 'Fira Code', 'Source Code Pro', monospace;
            max-width: 768px;
            margin: 0 auto;
            padding: 2rem 1.5rem;
            line-height: 1.6;
          }
          a { color: var(--orange); }
          a:hover { text-decoration: none; }
          header {
            margin-bottom: 2rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid rgba(255,168,106,0.3);
          }
          header .hint { color: var(--dim); font-size: 0.875rem; margin-bottom: 0.75rem; }
          h1 { color: var(--orange); font-size: 1.4rem; }
          article {
            padding: 1.25rem 0;
            border-bottom: 1px solid rgba(255,168,106,0.15);
          }
          article h2 { font-size: 1rem; font-weight: normal; }
          time { color: var(--dim); font-size: 0.875rem; display: block; margin-top: 0.2rem; }
        </style>
      </head>
      <body>
        <header>
          <p class="hint">Web feed (Atom) — paste this URL into your feed reader to subscribe.</p>
          <h1><xsl:value-of select="/atom:feed/atom:title"/></h1>
        </header>
        <main>
          <xsl:for-each select="/atom:feed/atom:entry">
            <article>
              <h2>
                <a>
                  <xsl:attribute name="href">
                    <xsl:value-of select="atom:link/@href"/>
                  </xsl:attribute>
                  <xsl:value-of select="atom:title"/>
                </a>
              </h2>
              <time>
                <xsl:value-of select="substring(atom:published, 1, 10)"/>
              </time>
            </article>
          </xsl:for-each>
        </main>
      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>
