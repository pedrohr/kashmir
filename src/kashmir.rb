class Kashmir
  attr_reader :graph, :knowledge_base

  def initialize(schemas)
    @source = Kashmir.extract_schema(schemas[:source])
    @target = Kashmir.extract_schema(schemas[:target])

    relative = Hash.new(0)
    @target.each do |a2|
      relative[a2] = nil
    end

    @graph = Hash.new(0)

    @source.each do |a1|
      @graph[a1] = relative
    end
  end

  def self.extract_schema(schema)
    return schema.gsub(' ', '').split(',').map {|s| s.to_sym}
  end

  # Characters are case sensitive
  def self.frequency_hash(string)
    frequency_hash = Hash.new(0)
    string.gsub(/\s/, '').split(//).each do |c|
      if frequency_hash[c].nil?
        frequency_hash[c] = 0
      else
        frequency_hash[c] += 1
      end
    end
    return frequency_hash
  end
  
  def process_knowledge_base_instance(instance)
    values = instance.split(',').map {|v| v.strip}
    hash_frequency_vectors = Hash.new(0)

    @source.each_with_index do |attribute, index|
      hash_frequency_vectors[attribute] = Kashmir.frequency_hash(values[index])
    end

    return hash_frequency_vectors
  end

  
  def process_knowledge_base(knowledge_base_file)
    @knowledge_base = Hash.new(0)

    @source.each do |attr|
      @knowledge_base[attr] = {}
    end

    File.open(knowledge_base_file, 'r').each_line do |instance|
      frequency_vector = process_knowledge_base_instance(instance)

      frequency_vector.each_pair do |k,v|
        v.each_pair do |char, sum|
          @knowledge_base[k][char] = (@knowledge_base[k][char].nil?) ? sum : @knowledge_base[k][char] + sum
        end
      end
    end
  end

  def self.cosine_distance(freq1, freq2)
    return 0 if freq1.empty? or freq2.empty?
    
    #optimizing...
    if freq1.size < freq2.size
      base = freq1.dup
      compare = freq2.dup
    else
      base = freq2.dup
      compare = freq1.dup
    end
    
    sum_base = 0
    sum_compare = 0
    dot_prod = 0
    
    base.each_pair do |key, value|
      sum_base += value * value
      image = (compare[key].nil?) ? 0 : compare[key]
      dot_prod += value * image
      sum_compare += image * image
      compare.delete(key)
    end
    
    compare.each_pair do |key,value|
      sum_compare += value * value
    end
    
    return dot_prod/Math.sqrt(sum_base * sum_compare)
  end

  def propagate_knowledge_base
    @graph.each_pair do |key, value|
      value.keys.each do |attribute|
        @graph[key][attribute] = @knowledge_base
      end
    end
  end

  def prepare_to_match(kb_filename)
    process_knowledge_base(kb_filename)
    propagate_knowledge_base
  end

  def find_best_match(new_instance)
    instance = new_instance.split(',').map {|v| v.strip}
    apply = Hash.new(0)

    @source.each_with_index do |attribute, index|
      hash_frequency_vectors[attribute] = Kashmir.frequency_hash(values[index])
    end

    
  end
end
