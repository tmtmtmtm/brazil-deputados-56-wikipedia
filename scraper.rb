#!/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'pry'
require 'scraped'
require 'wikidata_ids_decorator'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    members_table.xpath('.//tr[td]').map { |tr| fragment(tr => MemberRow).to_h }
  end

  private

  def members_table
    noko.xpath('//table[.//th[4][contains(.,"Votos nominais")]]')
  end
end

class MemberRow < Scraped::HTML
  field :id do
    tds[0].css('a/@wikidata').map(&:text).first
  end

  field :name do
    tds[0].css('a').map(&:text).map(&:tidy).first
  end

  field :partyLabel do
    tds[1].css('a').map(&:text).map(&:tidy).first || tds[1].xpath('text()').map(&:text).map(&:tidy).first
  end

  field :party do
    tds[1].css('a/@wikidata').map(&:text).first
  end

  field :areaLabel do
    area_header.text
  end

  field :area do
    area_header.attr('wikidata')
  end

  private

  def tds
    noko.css('td')
  end

  def area_header
    noko.xpath('preceding::h3').last.css('.mw-headline a').last
  end
end

url = 'https://pt.wikipedia.org/wiki/Lista_de_deputados_federais_do_Brasil_da_56.%C2%AA_legislatura'
data = Scraped::Scraper.new(url => MembersPage).scraper.members

header = data.first.keys.to_csv
rows = data.map { |row| row.values.to_csv }
puts header + rows.join
