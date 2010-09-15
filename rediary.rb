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
      keys_array << keys
    end

    keys = keys_array.inject {|x, y| x & y} || []

    titles = {}

    dir = File.expand_path(File.dirname(__FILE__))
    File.open("#{dir}/#{@name}.i", 'r') {|f|
      titles = eval(f.read)
    }

    keys.map {|x| titles[x]}
  end

  def [](identifer)
    identifer = identifer.to_s

    result = nil

    each_entry do |entry|
      if entry.id == identifer
        result = entry
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

      each_entry do |entry|
        index.upd(entry.id, nil, entry.body)
        f.puts %Q{"#{entry.id}" => %q{#{entry.title}},}
        count += 1

        yield entry if block_given?
      end

      f.puts "}"
    }

    index.close

    count
  end

  def each_entry
    dir = File.expand_path(File.dirname(__FILE__))
    doc = Nokogiri.HTML(open("#{dir}/#{@file_name}"))

    entries = []

    doc.search("//diary/day").each do |day|
      date = day.at("@date").value

      day.children.each do |body|
        if body.name == "text"
          entry = nil

          body.text.each_line do |line|
            if line =~ /^\*([0-9]+)\*[^\r\n|\r|\n]+/
              if entry
                entries << entry
                yield entry if block_given?
              end

              entry = Entry.new($1, $&, "") 
            end

            entry.body += line if entry
          end

          if entry
            entries << entry
            yield entry if block_given?
          end
        end
      end
    end

    entries
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
end


class Entry
  def initialize(id, title, body)
    @id = id
    @title = title
    @body = body
  end

  attr_accessor :id, :title, :body
end
