import os
import json
import scrapy

def load_old_output(path):
    '''
    Loads an old output into a form that can be used for hash checking
    '''
    if not os.path.exists(path):
        return {}
    with open(path, 'r') as f:
        output_json = json.load(f)
        return {j['url']: j['text'] for j in output_json}

class PapersSpider(scrapy.Spider):
    name = 'papers'
    allowed_domains = ['paperspast.natlib.govt.nz']
    start_urls = ['http://paperspast.natlib.govt.nz/newspapers/all/']

    def __init__(self, old_output, *args, **kwargs):
        super(scrapy.Spider, self).__init__(*args, **kwargs)
        self.old_output = load_old_output(old_output)

    def parse(self, response):

        newspaper_paths = response.xpath("//td/a/@href").extract()
        for path in newspaper_paths:
            newspaper_url = response.urljoin(path)
            yield scrapy.Request(newspaper_url, callback = self.parse_newspaper)

    def parse_newspaper(self, response):

        # Jump to the next page if it exists
        next_button = (response
            .xpath("//a[contains(@id,'calendar-next')]/@href")
        )
        if len(next_button) == 1:
            next_button = next_button.extract_first()
            next_newspaper_url = response.urljoin(next_button)
            yield scrapy.Request(next_newspaper_url, callback = self.parse_newspaper)


        issue_paths = response.xpath('//td/a/@href').extract()
        for path in issue_paths:
            issue_url = response.urljoin(path)
            yield scrapy.Request(issue_url, callback = self.parse_issue)

    def parse_issue(self, response):

        page_paths = (response
            .xpath('//ul[contains(@class,"issue__contents")]/descendant::a/@href')
            .extract()
        )

        for path in page_paths:
            page_url = response.urljoin(path)
            try:
                # Check if the page is cached already
                yield {
                    'url': page_url,
                    'text': self.old_output[page_url]
                }
            except KeyError:
                yield scrapy.Request(page_url, callback = self.parse_page)

    def parse_page(self, response):

        body_text = (response
                     .xpath('//div[contains(@itemprop,"articleBody")]/p/text()')
                     .extract()
        )

        yield {
            'url': response.url,
            'text': '\n'.join(body_text)
        }
