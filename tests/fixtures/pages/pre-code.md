# Code in a toggle

<details><summary>Quoted code is never read as Markdown</summary>
<p><b>1.</b> The check (<code>bin/tool</code>)</p>
<pre><code>[[ -f "$f" ]] || die "see [the docs](nope.md)"
**not bold** ==not a highlight== &lt;a href="%s"&gt;
> [!WARNING] quoted, not an alert
![shot](https://example.com/x.png)</code></pre>
<p>After the code, one <code>[[inline]]</code> sample and <pre><code>[[ one line ]]</code></pre> more.</p>
</details>
