require 'test/unit'
require File.dirname(__FILE__) + '/../lib/json-schema'

class ExtendsNestedTest < Test::Unit::TestCase

  def assert_validity(valid, schema, data, msg=nil)
    errors = JSON::Validator.fully_validate schema, data
    msg.sub! /\.$/, '' if msg
    send (valid ? :assert_equal : :refute_equal), [], errors, \
      "Schema should be #{valid ? :valid : :invalid}#{msg ? ".\n[#{schema.inspect}] #{msg}" : ''}"
  end

  def assert_valid(schema_name, data, msg=nil) assert_validity true, schema_name, data, msg end
  def refute_valid(schema_name, data, msg=nil) assert_validity false, schema_name, data, msg end

  %w[
    extends_and_additionalProperties-1-filename extends_and_additionalProperties-1-ref
    extends_and_additionalProperties-2-filename extends_and_additionalProperties-2-ref
  ].each do |schema_name|
    test_prefix= 'test_' + schema_name.gsub('-','_')

    JSON::Validator.cache_schemas=true
    JSON::Validator.add_schema(JSON::Schema.new(JSON.parse(File.read(File.expand_path("../schemas/inner.schema.json", __FILE__))), nil))

    schema = JSON.parse(File.read(File.expand_path("../schemas/#{schema_name}.schema.json", __FILE__)))

    define_method("#{test_prefix}_valid_outer") do
      assert_valid schema, {"outerC"=>true}, "Outer defn is broken, maybe the outer extends overrode it?"
    end

    define_method("#{test_prefix}_valid_outer_extended") do
      assert_valid schema, {"innerA"=>true}, "Extends at the root level isn't working."
    end

    define_method("#{test_prefix}_valid_inner") do
      assert_valid schema, {"outerB"=>[{"innerA"=>true}]}, "Extends isn't working in the array element defn."
    end

    define_method("#{test_prefix}_invalid_inner") do
      refute_valid schema, {"outerB"=>[{"whaaaaat"=>true}]}, "Array element defn allowing anything when it should only allow what's in inner.schema"
    end

    if schema_name['extends_and_additionalProperties-1']
      define_method("#{test_prefix}_invalid_outer") do
        refute_valid schema, {"whaaaaat"=>true}, "Outer defn allowing anything when it shouldn't."
      end
    end

  end
end
