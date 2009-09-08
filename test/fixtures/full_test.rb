function _template_full_test_lam()
local _out = {}; function out(s) table.insert(_out, tostring(s)); end table.insert(_out, tostring( include('header') )); 
 local videos = vodspot.videos({per_page = 15}) ; 
 local first_video = videos[1] ; 
table.insert(_out, "\n"); 
table.insert(_out, "<div id=\"col1\">\n"); 
table.insert(_out, "  <h1>Videos</h1>\n"); 
table.insert(_out, "  <p class=\"subheading\">featured video</p>\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "  <div id=\"featured_video\">  \n"); 
table.insert(_out, "    <a href=\""); table.insert(_out, tostring( first_video.url )); table.insert(_out, "\" class=\"thumbnail\">"); table.insert(_out, "\n"); 
table.insert(_out, tostring( first_video.embed_tag )); 
table.insert(_out, "    </a>\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "    <div class=\"metadata\">\n"); 
table.insert(_out, "      <h2><a href=\""); table.insert(_out, tostring( first_video.url )); table.insert(_out, "\" class=\"title\">"); table.insert(_out, tostring( first_video.title )); table.insert(_out, "</a></h2>"); table.insert(_out, "\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "      <p>\n"); 
table.insert(_out, "        <a href=\""); table.insert(_out, tostring( first_video.rss_from )); table.insert(_out, "\">Read the article</a>"); table.insert(_out, "\n"); 
table.insert(_out, "      </p>\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "      <p class=\"date\">\n"); 
table.insert(_out, tostring( time_ago(first_video.date) )); 
table.insert(_out, "      </p>\n"); 
table.insert(_out, "    </div>\n"); 
table.insert(_out, "    <div style=\"clear:both;\"></div>\n"); 
table.insert(_out, "  </div>\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "  <div id=\"video_grid\">\n"); 
table.insert(_out, "    <p class=\"subheading\">other videos</p>\n"); 
for i,video in ipairs(slice(videos,2,6)) do 
table.insert(_out, "    <div class=\"video "); if i%3==0 then table.insert(_out, "last"); end; table.insert(_out, "\">"); table.insert(_out, "\n"); 
table.insert(_out, "      <a href=\""); table.insert(_out, tostring( video.url )); table.insert(_out, "\" class=\"thumbnail\">"); table.insert(_out, "\n"); 
table.insert(_out, "        <img src=\""); table.insert(_out, tostring( video.thumbnail_160 )); table.insert(_out, "\" />"); table.insert(_out, "\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "        <div class=\"details\">\n"); 

table.insert(_out, "          <br/><br/><br/>\n"); 
table.insert(_out, "          \n"); 
if #video.tags > 0 then 
table.insert(_out, "          tags "); for i,tag in ipairs(video.tags) do table.insert(_out, "\n"); 
table.insert(_out, "          <b>"); table.insert(_out, tostring( tag.name )); table.insert(_out, "</b>, "); table.insert(_out, "\n"); 
end; 
end; 
table.insert(_out, "        </div>\n"); 
table.insert(_out, "      </a>\n"); 
table.insert(_out, "      <a href=\""); table.insert(_out, tostring(video.url)); table.insert(_out, "\" class=\"title\">"); table.insert(_out, tostring( video.title )); table.insert(_out, "</a>"); table.insert(_out, "\n"); 
table.insert(_out, "    </div>\n"); 
if i%3==0 then 
table.insert(_out, "    <div style=\"clear:both;\"></div>\n"); 
end; 
end; 
table.insert(_out, "    <div style=\"clear:both;\"></div>\n"); 
table.insert(_out, "  </div>\n"); 
table.insert(_out, "  \n"); 
table.insert(_out, "  <div class=\"video_list\">\n"); 
table.insert(_out, "    <p class=\"subheading\">older videos</p>\n"); 
table.insert(_out, "\n"); 
for i,video in ipairs(slice(videos,8,9)) do 
table.insert(_out, "    <div class=\"video\">\n"); 
table.insert(_out, "      <a href=\""); table.insert(_out, tostring( video.url )); table.insert(_out, "\" class=\"thumbnail\">"); table.insert(_out, "\n"); 
table.insert(_out, "        <img src=\""); table.insert(_out, tostring( video.thumbnail_160 )); table.insert(_out, "\" />"); table.insert(_out, "\n"); 
table.insert(_out, "      </a>\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "      <div class=\"details\">\n"); 
table.insert(_out, "        <a href=\""); table.insert(_out, tostring( video.url )); table.insert(_out, "\" class=\"title\">"); table.insert(_out, tostring( video.title )); table.insert(_out, "</a>"); table.insert(_out, "\n"); 
table.insert(_out, "        <br/><br/>\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "        <div style=\"text-transform:uppercase;font-size:0.8em\">\n"); 
table.insert(_out, tostring( time_ago(video.date) )); 
table.insert(_out, "          <br/>\n"); 
if #video.tags > 0 then 
table.insert(_out, "          tags "); for m,tag in ipairs(video.tags) do table.insert(_out, "\n"); 
table.insert(_out, tostring( '<b><a href="' .. tag.url .. '">' .. tag.name .. '</a></b>, ' )); 
end; 
end; 

table.insert(_out, "        </div>\n"); 
table.insert(_out, "      </div>\n"); 
table.insert(_out, "      <div style=\"clear:both;\"></div>\n"); 
table.insert(_out, "    </div>\n"); 
end; 
table.insert(_out, "  </div>\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "  <script>\n"); 
table.insert(_out, "  var highlighted_video = null;\n"); 
table.insert(_out, "  $j(document).ready(function() {\n"); 
table.insert(_out, "    $j('#video_grid .video img').mouseover(function(event) {\n"); 
table.insert(_out, "      if (highlighted_video != null) {\n"); 
table.insert(_out, "        $j('.details', highlighted_video).animate({height:'14px'});\n"); 
table.insert(_out, "      }\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "      highlighted_video = this.parentNode;\n"); 
table.insert(_out, "      $j('.details', this.parentNode).animate({height:'123px'})\n"); 
table.insert(_out, "    });\n"); 
table.insert(_out, "  });\n"); 
table.insert(_out, "  </script>\n"); 
table.insert(_out, "</div>\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "<div id=\"col_right\">\n"); 
table.insert(_out, tostring( util.remote_snippet('http://www.techcrunch.com', 'div#col2 > ul.sponsor_units') )); 
table.insert(_out, "  \n"); 
table.insert(_out, "  <div id=\"tag_list\">\n"); 
table.insert(_out, "    <h2>Other Videos</h2>\n"); 
 for i,tag in ipairs(util.split(vodspot.config('tag_list'), ',')) do  
 video = vodspot.videos({tag = tag, per_page = 1})[1] ; 
 if video ~= null then  
table.insert(_out, "    <div class=\"tag\">\n"); 
table.insert(_out, "      <a href=\"/tag/"); table.insert(_out, tostring(tag)); table.insert(_out, "\"><img src=\""); table.insert(_out, tostring( video.thumbnail_100 )); table.insert(_out, "\" style=\"float:left;\"/></a>"); table.insert(_out, "\n"); 
table.insert(_out, "      <div style=\"float:left;display:inline;margin-left:10px;\">\n"); 
table.insert(_out, "        <h2><a href=\"/tag/"); table.insert(_out, tostring(tag)); table.insert(_out, "\">"); table.insert(_out, tostring( tag )); table.insert(_out, "</a></h2>"); table.insert(_out, "\n"); 
table.insert(_out, tostring( vodspot.total_videos({tag = tag}) )); table.insert(_out, " videos"); table.insert(_out, "\n"); 
table.insert(_out, "      </div>\n"); 
table.insert(_out, "      <div style=\"clear:both;\"></div>\n"); 
table.insert(_out, "    </div>\n"); 
 end ; 
 end ; 
table.insert(_out, "  </div>\n"); 
table.insert(_out, "  \n"); 
table.insert(_out, tostring( util.remote_snippet('http://www.techcrunch.com/2009/', 'div#col2 #sidebar_features') )); 
table.insert(_out, "  \n"); 
table.insert(_out, "</div>\n"); 
table.insert(_out, "<div style=\"clear:both;\"></div>\n"); 
return table.concat(_out)
end