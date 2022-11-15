import sys
import json

from urllib.request import urlopen
from bs4 import BeautifulSoup

from html2image import Html2Image
hti = Html2Image(output_path='./gen/')

IMAGES_IN_ROW = 20
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
        height: 224px;
        display: flex;
        flex-direction: row;
      }

      img {
        width: 123px;
        height: 224px;
      }
    </style>
</style>
"""



CHECK_URIS = True

def inner_uri_soup(top_uri, idx, print_uri=True):
    page = urlopen(top_uri)
    soup = BeautifulSoup(page, 'html.parser')

    imguri = json.loads(str(soup))['image']


    #print('===========URI: ' + imguri)
    #png = html2png.render(imguri)
    #hti.screenshot(url=imguri, save_as=f'{idx}.png')
    if print_uri:
        print(f'<a href="{imguri}">Trainer {idx}</a>')
    page = urlopen(imguri)
    soup = BeautifulSoup(page, 'html.parser')
    return soup


def imgFromUri(top_uri):
    page = urlopen(top_uri)
    soup = BeautifulSoup(page, 'html.parser')

    return json.loads(str(soup))['image']


def inner_uris(in_fname):
    with open(in_fname, "r") as uri_file:
        uris = json.load(uri_file)
        #mega_html = f'{style}<div><table><tr id="images">'
        mega_html = f'{style}<section class="grid"><div class="row">'
        #mega_html = f'<div>'
        for i, top_uri in enumerate(uris):
            #soup = inner_uri_soup(top_uri, i, i == len(uris)-1)
            imguri = imgFromUri(top_uri)
            #mega_html += '<td>' + soup.prettify() + '</td>'
            #mega_html += '<td><img style="display:block;" src="' + imguri + '" alt="" width="100%" height="100%"/></td>'
            if False:
                mega_html += f'<a href="{imguri}">Trainer {i + 1}</a>'
            mega_html += '<img src="' + imguri + '" alt=""/>'
            if not (i+1) % IMAGES_IN_ROW and i < len(uris):
                mega_html += '</div><div class="row">'


        #mega_html += '</tr></table></div>'
        mega_html += '</div></section>'
        print(mega_html)
        return mega_html


assert len(sys.argv) > 1, "Provide path to image metadata JSON"

# FIXME require that the file exists
grid_html = inner_uris(sys.argv[1])

hti.screenshot(html_str=grid_html, save_as='mega.png')
