require "rubygems"
require "nokogiri"
require "senna"


class ReDiary
  def initialize(name)
    @name = name
    @file_name = name + ".xml"
  end

  def search(word)
    keys_array = []

    word.split(/\s|　/).each do |w|
      keys = search_a_word(w)
      keys_array << keys if 0 < keys.size
    end

    keys = keys_array.inject {|x, y| x & y} || []

    titles = {}

    dir = File.expand_path(File.dirname(__FILE__))
    File.open("#{dir}/#{@name}.i", 'r') {|f|
      titles = eval(f.read)
    }

    keys.map {|x| titles[x]}
  end

  private
  def search_a_word(word)
    dir = File.expand_path(File.dirname(__FILE__))
    index = Senna::Index::open("#{dir}/#{@name}")
    r = index.sel(word)

    keys = []

    if r
      r.each do |key, score|
        keys << key
      end
    end

    keys
  end

  def [](identifer)
    identifer = identifer.to_s

    result = nil

    each_entry do |id, title, body|
      if id == identifer
        result = body
        break
      end
    end

    result
  end

  def reindex!
    dir = File.expand_path(File.dirname(__FILE__))
    index = Senna::Index.create("#{dir}/#{@name}", 0, 0, 0, Senna::ENC_UTF8)
    # N-gram
    # index = Senna::Index.create(@name, 0, (Senna::INDEX_NORMALIZE | Senna::INDEX_NGRAM), 0, Senna::ENC_UTF8)

    count = 0

    File.open("#{dir}/#{@name}.i", 'w') {|f|
      f.puts "{"

      each_entry do |id, title, body|
        index.upd(id, nil, body)
        f.puts %Q{"#{id}" => %q{#{title}},}
        count += 1

        #
        puts id
      end

      f.puts "}"
    }

    index.close

    count
  end

  def each_entry
    dir = File.expand_path(File.dirname(__FILE__))
    doc = Nokogiri.HTML(open("#{dir}/#{@file_name}"))

    doc.search("//diary/day").each do |day|
      date = day.at("@date").value

      day.children.each do |body|
        if body.name == "text"
          body.text.scan(/^\*[0-9]+\*[^\r\n|\r|\n]+/) do |title|
            id = title.scan(/^\*([0-9]+)\*/)[0][0]
            yield id, title, body.text
          end
        end
      end
    end
  end
end
