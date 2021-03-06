require "compiler/crystal/syntax"

class Object
  private def cast_node(node : Crystal::ASTNode)
    case node
    when Crystal::StringLiteral            then node.value
    when Crystal::CharLiteral              then node.value
    when Crystal::BoolLiteral              then node.value
    when Crystal::NilLiteral, Crystal::Nop then nil
    when Crystal::NumberLiteral
      case node.kind
      when :f32 then node.value.to_f32
      when :f64 then node.value.to_f64
      else           node.integer_value
      end
    when Crystal::RangeLiteral
      Range.new(
        cast_node(node.from).as(Int::Primitive?),
        cast_node(node.to).as(Int::Primitive?),
        node.exclusive?
      )
    else
      raise "unsupported node type: #{node} (#{node.class}}"
    end
  end

  def send(call : String)
    args = nil
    name = nil
    node = Crystal::Parser.parse "self." + call

    {% begin %}
    {% args = %w(0 1 2 3 4 5 6 7 8 9) %}
    {% supported_types = %w(Int Bool Char Float32 Float64 Int16 Int32 Int64 Int8 String UInt16 UInt32 UInt64 UInt8 Nil Range) %}

    case node
    when Crystal::Call
      name = node.name
      args = node.args
      raise "max number of arguments reached: {{args.last.id}}" if args.size > {{args.last.id}}
      method_with_args = case args.size
      {% for arg_num in args %}\
      when {{arg_num.id}}
        { name {% for local_arg_num in args %}{% if local_arg_num < arg_num %}, cast_node(args[{{local_arg_num.id}}]){% end %}{% end %} }
      {% end %}
      end
    end

    case method_with_args
    when nil then raise "unsupported call: #{call}"
    {% methods = @type.methods %}\
    {% for type in @type.ancestors %}\
      {% methods = methods + type.methods %}\
    {% end %}\
    {% used_methods = {} of String => Bool? %}\
    {% for method in methods %}
      # {{method.name}} {{method.args}}
      {% if method.accepts_block? ||
              used_methods[method.name.stringify + method.args.map(&.restriction.stringify).join("")] ||
              %w(sum transpose product to_h).includes?(method.name.stringify) %}\
      {% elsif method.args.all? &.restriction.stringify.split(" | ").all? { |t| supported_types.includes? t } %}\
      {% method_args = "" %}\
      when { {{method.name.stringify}} {% for arg in method.args %}\
              , {{arg.restriction}}\
              {% method_args = method_args + arg.restriction.stringify %}\
          {% end %}\ }
          {% i = 0 %}\
          self.{{method.name}}(
          {% for arg in method.args %}\
            {% i = i + 1 %}\
            method_with_args[{{i.id}}]?.as({{arg.restriction}}){% if method.args.size > 1 %},{% end %}\
          {% end %}\
          )
        {% used_methods[method.name.stringify + method_args] = true %}\
        {% end %}\
      {% end %}\
    else
      raise "unsupported method: #{method_with_args}"
    end
    {% end %}
  end
end
