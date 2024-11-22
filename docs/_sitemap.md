---
layout: default
title: Sitemap
permalink: /sitemap
---
<!-- https://jekyllrb.com/docs/posts/#displaying-an-index-of-posts --> 

<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a>
    </li>
  {% endfor %}
  {% for page in site.page %}
    <li>
      <a href="{{ page.url }}">{{ page.title }}</a>
    </li>
  {% endfor %}
</ul>