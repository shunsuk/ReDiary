require "ReDiary"


ENTRIES = [
  Entry.new("1234567890", "*1234567890*[書式]アスタリスク*入り*日記", "*1234567890*[書式]アスタリスク*入り*日記\nアスタリスク*入り*日記です。\n\nアスタリスク*入り*日記です。\n\n** 見出し\n\n見出しのテストです。\n\n見出しのテストです。\n\n"),
  Entry.new("1234567891", "*1234567891*[複数][最初]複数日記（最初）", "*1234567891*[複数][最初]複数日記（最初）\n複数日記（最初）です。\n\n"),
  Entry.new("1234567892", "*1234567892*[複数][中]複数日記（中）", "*1234567892*[複数][中]複数日記（中）\n複数日記（中）です。\n\n"),
  Entry.new("1234567893", "*1234567893*[複数][最後]複数日記（最後）", "*1234567893*[複数][最後]複数日記（最後）\n複数日記（最後）です。\n\n"),
  Entry.new("1234567895", "*1234567895*[コメント]コメント付き日記", "*1234567895*[コメント]コメント付き日記\nコメント付き日記です。\n\n")
]
INDEX_FILES = [
  "test.SEN",
  "test.SEN.i",
  "test.SEN.i.c",
  "test.SEN.l",
  "test.i"
]


describe ReDiary, "when enumerate the entries" do
  before do
    @rediary = ReDiary.new "test"
  end

  it "should raise an error with a wrong name" do
    @rediary = ReDiary.new "wrong"
    lambda { @rediary.each_entry }.should raise_error(Errno::ENOENT)
  end

  it "should process given block" do
    count = 0
    @rediary.each_entry {|entry| count += 1}
    count.should ==  ENTRIES.size
  end

  it "should return entries" do
    entries = @rediary.each_entry
    entries.size.should == ENTRIES.size

    entries.zip(ENTRIES).each do |a, b|
      a.id.should == b.id
      a.title.should == b.title
      a.body.should == b.body
    end
  end

  after do
    @rediary = nil
  end
end


describe ReDiary, "when create index" do
  before do
    @rediary = ReDiary.new "test"
  end

  it "should create index files" do
    dir = File.expand_path(File.dirname(__FILE__))

    count = @rediary.reindex!
    count.should == ENTRIES.size
    
    INDEX_FILES.each do |file|
      path = "#{dir}/#{file}"
      File.exist?(path).should be_true
    end
  end

  after do
    @rediary = nil
  end
end


describe ReDiary, "when search entries" do
  before do
    @rediary = ReDiary.new "test"
  end

  it "should return correct results" do
    @rediary.search("複数").size.should == 3
    @rediary.search("最初").size.should == 1
    @rediary.search("複数 最初").size.should == 1

    result = @rediary.search("アスタリスク")
    result[0] == ENTRIES[0].id
  end

  after do
    @rediary = nil
  end
end


describe ReDiary, "when show an entry" do
  before do
    @rediary = ReDiary.new "test"
  end

  it "should show a correct entry" do
    ENTRIES.each do |entry|
      result = @rediary[entry.id]
      result.id.should == entry.id
      result.title.should == entry.title
      result.body.should == entry.body
    end
  end

  after do
    @rediary = nil
  end
end
