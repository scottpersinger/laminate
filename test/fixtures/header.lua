function _template_header()
local _out = {}; function out(s) table.insert(_out, tostring(s)); end; table.insert(_out, "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n"); 
table.insert(_out, "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">\n"); 
table.insert(_out, "  <head>\n"); 
table.insert(_out, "    <title>Colbert Nation</title>\n"); 
table.insert(_out, "    <meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\" />\n"); 
table.insert(_out, "    <link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" href=\"/videos.rss\" />\n"); 
table.insert(_out, "    <script src=\"/javascripts/jquery.min.js\"></script>\n"); 
table.insert(_out, "    <script src=\"/javascripts/hosted_jquery.js\"></script>\n"); 
table.insert(_out, "    <!-- pretty photo lightbox -->\n"); 
table.insert(_out, "    <link rel=\"stylesheet\" href=\"/stylesheets/hosted/prettyPhoto.css\" type=\"text/css\" media=\"screen\" charset=\"utf-8\" />\n"); 
table.insert(_out, "    <script src=\"/javascripts/hosted/jquery.prettyPhoto.js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "    \n"); 
table.insert(_out, "    <link type=\"text/css\" rel=\"stylesheet\" media=\"all\" href=\""); table.insert(_out,  stylesheet_url('base') ); table.insert(_out, "\"/>"); table.insert(_out, "\n"); 
table.insert(_out, "      \n"); 
table.insert(_out, "  </head>\n"); 
table.insert(_out, "  <body>\n"); 
table.insert(_out, "    <div id=\"wrapper\" style=\"min-width:980px;\">\n"); 
table.insert(_out, "	  <div id=\"container\" style=\"margin: 0 auto; width:980px\">\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "      <img src=\"/stylesheets/hosted/inline_playback/colbert_header.png\" />		\n"); 
return table.concat(_out)
end