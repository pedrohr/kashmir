require 'test/unit'
require '../src/kashmir'

# Attribute names are always URI's. No spaces allowed inside names
# The ordering of values in knowledge_base is aligned with the order in schemas

class TestKashmir < Test::Unit::TestCase
  def setup
    @schema1 = "name, city, age"
    @schema2 = "full_name, language, reg_age, origin_city"

    @match = Kashmir.new({:source => @schema2, :target => @schema1})

    @knowledge_base = ["Pedro, english, 23, Rio de Janeiro", 
                       "Brian, french, 30, New York",
                       "Mark, english, , San Francisco"].join("\n")
  end

  def test_extract_schema
    schema = Kashmir.extract_schema(@schema1)
    assert_equal(schema, [:name, :city, :age])
  end

  def test_schema_read
    graph = @match.graph
    assert_equal(graph, {:full_name => {:name => nil, :city => nil, :age => nil},
                   :language => {:name => nil, :city => nil, :age => nil},
                   :reg_age => {:name => nil, :city => nil, :age => nil},
                   :origin_city => {:name => nil, :city => nil, :age => nil}})
  end

  def test_creation_frequency_vector
    string = "Rio de Janeiro"
    assert_equal(Kashmir.frequency_hash(string), {"R" => 1, "r" => 1, "i" => 2, "o" => 2, "d" => 1, "e" => 2, "J" => 1, "a" => 1, "n" => 1})
  end

  def _get_complete_instance(string)
    return string.split("\n").first
  end

  def _get_incomplete_instance(string)
    return string.split("\n").last
  end

  # Extraction of vectors are case sensitive
  def test_process_instance_knowledge_base
    processed = @match.process_knowledge_base_instance(_get_complete_instance(@knowledge_base))

    assert_equal(processed, 
                 {:full_name => {"P" => 1, "e" => 1, "d" => 1, "r" => 1, "o" => 1},
                   :language => {"e" => 1, "n" => 1, "g" => 1, "l" => 1, "i" => 1, "s" => 1, "h" => 1},
                   :reg_age => {"2" => 1, "3" => 1},
                   :origin_city => {"R" => 1, "r" => 1, "i" => 2, "o" => 2, "d" => 1, "e" => 2, "J" => 1, "a" => 1, "n" => 1}})


    processed = @match.process_knowledge_base_instance(_get_incomplete_instance(@knowledge_base))
    assert_equal(processed,
                 {:full_name => {"M" => 1, "a" => 1, "r" => 1, "k" => 1},
                   :language => {"e" => 1, "n" => 1, "g" => 1, "l" => 1, "i" => 1, "s" => 1, "h" => 1},
                   :reg_age => {},
                   :origin_city => {"S" => 1, "a" => 2, "n" => 2, "F" => 1, "r" => 1, "c" => 2, "i" => 1, "s" => 1, "o" => 1}})
  end

  def _create_kb_test_file(filename)
    kbf = File.open(filename, 'w')
    kbf.write(@knowledge_base)
    kbf.close
  end

  def test_process_konwledge_base
    kb_filename = "knowledge_base_test_file"
    _create_kb_test_file(kb_filename)

    @match.process_knowledge_base(kb_filename)
    assert_equal(@match.knowledge_base,
                 {:full_name => {"P" => 1, "e" => 1, "d" => 1, "B" => 1, "M" => 1, "a" => 1, "r" => 3, "k" => 1, "o" => 1, "i" => 1, "a" => 2, "n" => 1},
                   :language => {"e" => 3, "n" => 3, "g" => 2, "l" => 2, "i" => 2, "s" => 2, "h" => 3, "f" => 1, "r" => 1, "c" => 1},
                   :reg_age => {"2" => 1, "3" => 2, "0" => 1},
                   :origin_city => {"R" => 1, "S" => 1, "a" => 3, "n" => 3, "F" => 1, "r" => 3, "c" => 2, "i" => 3, "s" => 1, "o" => 4, "d" => 1, "e" => 3, "J" => 1, "N" => 1, "w" => 1, "Y" => 1, "k" => 1}})
  end

  def test_cosine_distance
    hash1 = {}
    hash2 = {"a" => 5, "c" => 4, "e" => 10}
    assert_equal(Kashmir.cosine_distance(hash1, hash2), 0)

    hash1 = {"a" => 2, "b" => 1, "c" => 3}
    assert_equal(Kashmir.cosine_distance(hash1, hash2), 0.495164050266978)
  end

  def test_propagate_knowledge_base
    @match.propagate_knowledge_base
    content = nil
    assert_equal(@match.graph, {:full_name => {:name => content, :city => content, :age => content},
                   :language => {:name => content, :city => content, :age => content},
                   :reg_age => {:name => content, :city => content, :age => content},
                   :origin_city => {:name => content, :city => content, :age => content}})

    kb_filename = "knowledge_base_test_file"
    _create_kb_test_file(kb_filename)
    @match.process_knowledge_base(kb_filename)

    @match.propagate_knowledge_base
    content = @match.knowledge_base
    assert_equal(@match.graph, {:full_name => {:name => content, :city => content, :age => content},
                   :language => {:name => content, :city => content, :age => content},
                   :reg_age => {:name => content, :city => content, :age => content},
                   :origin_city => {:name => content, :city => content, :age => content}})
  end

  def test_prepare_to_match
    kb_filename = "knowledge_base_test_file"
    _create_kb_test_file(kb_filename)

    @match.prepare_to_match(kb_filename)

    content = @match.knowledge_base
    assert_equal(@match.graph, {:full_name => {:name => content, :city => content, :age => content},
                   :language => {:name => content, :city => content, :age => content},
                   :reg_age => {:name => content, :city => content, :age => content},
                   :origin_city => {:name => content, :city => content, :age => content}})
  end

  def test_find_best_match
    kb_filename = "knowledge_base_test_file"
    _create_kb_test_file(kb_filename)

    @match.prepare_to_match(kb_filename)

    new_instance = ["Peter, London, 26"]

    match = @match.find_best_match(new_instance)
    assert_equal(match, {:name => :full_name, :city => :origin_city, :age => :reg_age})
  end
end
