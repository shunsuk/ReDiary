require "rubygems"
require "nokogiri"
require "senna"


class ReDiary
  def initialize(name)
    @name = name
    @file_name = name + ".xml"
  end

  def search(word)
    index = Senna::Index::open(@name)
    r = index.sel(word)

    result = []

    if r
      titles = {}

      File.open("#{@name}.i", 'r') {|f|
        titles = eval(f.read)
      }

      r.each do |key, score|
        title = titles[key]
        result << title

        yield key, title if block_given?
      end
    end

    result
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
    index = Senna::Index.create(@name, 0, 0, 0, Senna::ENC_UTF8)

    count = 0

    File.open("#{@name}.i", 'w') {|f|
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
    doc = Nokogiri.HTML(open(@file_name))

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
