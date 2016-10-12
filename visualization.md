---
layout: page
title: visualization
---

### Data visualization

* <a href = "/resources/pdf/Data Visualization Process.pdf" id = "visprocess"
target = "_blank" onclick="trackOutboundLink('DataVisualizationProcess.pdf');">Data Visualization Process</a> [Laura Hughes]
* <a href = "/resources/pdf/Takeaways for Good Visualization.pdf"
target = "_blank" onclick="trackOutboundLink('DataVisualizationTakeaways.pdf');">Takeaways for Effective Visualizations</a> [Laura Hughes]
<br>



### Data visualization in Excel
<ul class="post-list">
  {% for post in site.posts %}
  <li class="gallery">

    <!-- title/link -->
      <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>


    </li>



    {% endfor %}
  </ul>
