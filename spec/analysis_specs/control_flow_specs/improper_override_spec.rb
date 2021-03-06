require_relative 'spec_helper'

describe 'Improper override inference' do
  %w(to_s to_str).each do |method|
    it "should warn against a method named #{method} that doesn't always return a string" do
      cfg <<-EOF
class OverI1#{method}
  def #{method}
    gets.strip!  # whoops, ! means nil sometimes
  end
end
EOF
      ClassRegistry["OverI1#{method}"].instance_method(method).
          return_type_for_types(
            ClassRegistry["OverI1#{method}"].as_type)  # force calculation
      ClassRegistry["OverI1#{method}"].instance_method(method).proc.ast_node.should(
          have_error(ImproperOverrideTypeError).with_message(/#{method}/))
    end

    it "should not warn against a method named #{method} that always returns a string" do
      cfg <<-EOF
class OverI3#{method}
  def #{method}
    gets.to_s.strip
  end
end
EOF
      ClassRegistry["OverI3#{method}"].instance_method(method).
          return_type_for_types(
            ClassRegistry["OverI3#{method}"].as_type)  # force calculation
      ClassRegistry["OverI3#{method}"].instance_method(method).proc.ast_node.should_not(
          have_error(ImproperOverrideTypeError))
    end
  end

  %w(to_i to_int).each do |method|
    it "should warn against a method named #{method} that doesn't always return an integer" do
      cfg <<-EOF
class OverI2#{method}
  def #{method}
    gets.to_i * 2.0  # whoops, returns a float, not an int
  end
end
EOF
      ClassRegistry["OverI2#{method}"].instance_method(method).
          return_type_for_types(
            ClassRegistry["OverI2#{method}"].as_type)  # force calculation
      ClassRegistry["OverI2#{method}"].instance_method(method).proc.ast_node.should(
          have_error(ImproperOverrideTypeError).with_message(/#{method}/))
    end

    it "should not warn against a method named #{method} that always returns an integer" do
      cfg <<-EOF
class OverI3#{method}
  def #{method}
    gets.to_i
  end
end
EOF
      ClassRegistry["OverI3#{method}"].instance_method(method).
          return_type_for_types(
            ClassRegistry["OverI3#{method}"].as_type)  # force calculation
      ClassRegistry["OverI3#{method}"].instance_method(method).proc.ast_node.should_not(
          have_error(ImproperOverrideTypeError))
    end
  end

  %w(to_a to_ary).each do |method|
    it "should warn against a method named #{method} that doesn't always return an array" do
      cfg <<-EOF
class OverI2#{method}
  def #{method}
    [gets, gets, gets].compact!  # could return nil
  end
end
EOF
      ClassRegistry["OverI2#{method}"].instance_method(method).
          return_type_for_types(
            ClassRegistry["OverI2#{method}"].as_type)  # force calculation
      ClassRegistry["OverI2#{method}"].instance_method(method).proc.ast_node.should(
          have_error(ImproperOverrideTypeError).with_message(/#{method}/))
    end

    it "should not warn against a method named #{method} that always returns an array" do
      cfg <<-EOF
class OverI3#{method}
  def #{method}
    [gets, gets, gets].compact
  end
end
EOF
      ClassRegistry["OverI3#{method}"].instance_method(method).
          return_type_for_types(
            ClassRegistry["OverI3#{method}"].as_type)  # force calculation
      ClassRegistry["OverI3#{method}"].instance_method(method).proc.ast_node.should_not(
          have_error(ImproperOverrideTypeError))
    end
  end

  it "should warn against a method named to_f that doesn't always return an array" do
    cfg <<-EOF
class OverI2to_f
  def to_f
    [1.0, 2.0, 3.0][gets.to_i]  # could return nil
  end
end
EOF
    ClassRegistry["OverI2to_f"].instance_method(:to_f).
        return_type_for_types(
          ClassRegistry["OverI2to_f"].as_type)  # force calculation
    ClassRegistry["OverI2to_f"].instance_method(:to_f).proc.ast_node.should(
        have_error(ImproperOverrideTypeError).with_message(/to_f/))
  end


  it "should not warn against a method named to_f that alwayss return a float" do
    cfg <<-EOF
class OverI3
  def to_f
    gets.to_s.size * 3.4
  end
end
EOF
    ClassRegistry["OverI3"].instance_method(:to_f).
        return_type_for_types(
          ClassRegistry["OverI3"].as_type)  # force calculation
    ClassRegistry["OverI3"].instance_method(:to_f).proc.ast_node.should_not(
        have_error(ImproperOverrideTypeError))
  end

  it "should warn against a method named ! that doesn't always return a boolean" do
    cfg <<-EOF
class OverI2
  def !
    [true, false][gets.to_i]  # could return nil
  end
end
EOF
    ClassRegistry["OverI2"].instance_method(:!).
        return_type_for_types(
          ClassRegistry["OverI2"].as_type)  # force calculation
    ClassRegistry["OverI2"].instance_method(:!).proc.ast_node.should(
        have_error(ImproperOverrideTypeError).with_message(/\!/))
  end

  it "should not warn against a method named ! that always returns a boolean" do
    cfg <<-EOF
class OverI3
  def !
    gets == gets
  end
end
EOF
    ClassRegistry["OverI3"].instance_method(:!).
        return_type_for_types(
          ClassRegistry["OverI3"].as_type)  # force calculation
    ClassRegistry["OverI3"].instance_method(:!).proc.ast_node.should_not(
        have_error(ImproperOverrideTypeError))
  end

  it 'should warn when a method whose name ends in ? does not return both truthy and falsy at some point' do
    cfg <<-EOF
class OverI4
  def silly?(x, y)
    x
  end
end
EOF
    ClassRegistry["OverI4"].instance_method(:silly?).
        return_type_for_types(
          ClassRegistry["OverI4"].as_type, [Types::FIXNUM, Types::FIXNUM])
    ClassRegistry["OverI4"].instance_method(:silly?).
        return_type_for_types(
          ClassRegistry["OverI4"].as_type, [Types::STRING, Types::FIXNUM])
    MethodAnalysis.incorrect_predicate_methods.should include(
        ClassRegistry["OverI4"].instance_method(:silly?))
  end

  it 'should not warn when a method whose name ends in ? does return a bool | nil' do
    cfg <<-EOF
class OverI5
  def silly?(x, y)
    x == y || nil
  end
end
EOF
    ClassRegistry["OverI5"].instance_method(:silly?).
        return_type_for_types(
          ClassRegistry["OverI5"].as_type, [Types::FIXNUM, Types::FIXNUM])
    MethodAnalysis.incorrect_predicate_methods.should_not include(
        ClassRegistry["OverI5"].instance_method(:silly?))
  end

  %w(public private protected module_function).each do |method|
    it "should warn when the visibility method Module##{method} is overridden" do
      cfg <<-EOF
class OverI6
  def self.#{method}(*args)
    super
  end
end
EOF
      ClassRegistry["OverI6"].singleton_class.instance_method(method).proc.ast_node.should(
          have_error(DangerousOverrideError).with_message(/#{method}/))
    end
  end

  %w(block_given? iterator? binding callcc caller __method__ __callee__).each do |method|
    it "should warn when the visibility method Kernel##{method} is overridden" do
      cfg <<-EOF
class OverI7
  def #{method}(*args)
    super
  end
end
EOF
      ClassRegistry["OverI7"].instance_method(method).proc.ast_node.should(
          have_error(DangerousOverrideError).with_message(/#{method}/))
    end
  end

  OverrideSafetyInfo::KERNEL_SUPER_NEEDED.each do |method|
    it "should warn when Kernel##{method} is overridden without guaranteed super" do
      cfg <<-EOF
class OverI8
  def #{method}(*args)
    if args.first == :hello
      super(:hello)
    end
  end
end
EOF
      ClassRegistry["OverI8"].instance_method(method).proc.ast_node.should(
          have_error(OverrideWithoutSuperError).with_message(/#{method}/))
    end

    it "should not warn when Kernel##{method} is overridden with a guaranteed super" do
      g = cfg <<-EOF
class OverI9
  def #{method}(*args)
    p args
    super(:hello)
  end
end
EOF
      ClassRegistry["OverI9"].instance_method(method).proc.ast_node.should_not(
          have_error(OverrideWithoutSuperError))
    end
  end

  OverrideSafetyInfo::MODULE_SUPER_NEEDED.each do |method|
    it "should warn when Module##{method} is overridden without guaranteed super" do
      cfg <<-EOF
class OverI10
  def self.#{method}(*args)
    if args.first == :hello
      super(:hello)
    end
  end
end
EOF
      ClassRegistry["OverI10"].singleton_class.instance_method(method).proc.ast_node.should(
          have_error(OverrideWithoutSuperError).with_message(/#{method}/))
    end

    it "should not warn when Kernel##{method} is overridden with a guaranteed super" do
      g = cfg <<-EOF
class OverI11
  def self.#{method}(*args)
    p args
    super(:hello)
  end
end
EOF
      ClassRegistry["OverI11"].singleton_class.instance_method(method).proc.ast_node.should_not(
          have_error(OverrideWithoutSuperError))
    end
  end
end
