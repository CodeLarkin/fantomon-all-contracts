import sys
import json

from urllib.request import urlopen
from bs4 import BeautifulSoup


from html2image import Html2Image
hti = Html2Image(output_path='./gen/')

#<style>
#    #images  {
#        width: 1800px;
#        height: 446px;
#    }
#    #images img {
#        float: left;
#        white-space: nowrap;
#    }
style = """
</style>
    <style>
      .grid {
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
      }

      .row {
        width: 100%;
        height: 225px;
        display: flex;
        flex-direction: row;
      }

      .col {
        width: 100%;
        height: 225px;
        display: flex;
        flex-direction: row;
      }

      img {
        width: 123px;
        height: 225px;
      }
    </style>
"""


#BASE_URI = "https:/ipfs.io/ipfs/bafybeiflv73imoehfdiuovdffv3sazj3teezeohao4pb4oyafswoapom5e/";

CHECK_URIS = True


def imgFromUri(top_uri):
    page = urlopen(top_uri)
    soup = BeautifulSoup(page, 'html.parser')

    return json.loads(str(soup))['image']


def inner_uris(in_fname, width):
    with open(in_fname, "r") as uri_file:
        uris = json.load(uri_file)
        #mega_html = f'{style}<div><table><tr id="images">'
        mega_html = f'{style}<section class="grid"><div class="row">'
        #mega_html = f'<div>'
        for i, top_uri in enumerate(uris):
            imguri = imgFromUri(top_uri)
            #mega_html += '<td>' + soup.prettify() + '</td>'
            #mega_html += '<td><img style="display:block;" src="' + img_uri + '" alt="" width="100%" height="100%"/></td>'
            if False:
                mega_html += f'<a href="{imguri}">Fantomon {i + 1}</a>'
            mega_html += '<img src="' + imguri + '" alt=""/>'
            if not (i+1) % width and i < len(uris):
                mega_html += '</div><div class="row">'


        #mega_html += '</tr></table></div>'
        mega_html += '</div></section>'
        print(mega_html)
        return mega_html


assert len(sys.argv) > 1, "Provide path to image metadata JSON"

# FIXME require that the file exists
width = sys.argv[2] if len(sys.argv) > 2 else 18
grid_html = inner_uris(sys.argv[1], int(width))

hti.screenshot(html_str=grid_html, save_as='mega.png')
