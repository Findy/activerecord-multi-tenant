# frozen_string_literal: true

require 'arel'
require 'activerecord-multi-tenant/arel_visitors_depth_first'

describe MultiTenant::ArelVisitorsDepthFirst do
  let(:visited) { [] }
  let(:visitor) { described_class.new(->(node) { visited << node }) }
  let(:table) { Arel::Table.new(:projects) }
  let(:expr) { table[:id] }

  describe 'function nodes' do
    %i[Avg Exists Max Min Sum].each do |const_name|
      it "traverses Arel::Nodes::#{const_name} without raising" do
        node = Arel::Nodes.const_get(const_name).new([expr])

        expect { visitor.accept(node) }.not_to raise_error
        expect(visited).to include(expr)
      end
    end
  end

  describe 'Arel::Nodes::NamedFunction' do
    it 'traverses the node without raising' do
      node = Arel::Nodes::NamedFunction.new('coalesce', [expr])

      expect { visitor.accept(node) }.not_to raise_error
      expect(visited).to include(expr)
    end

    it 'visits the alias when the node still exposes #alias (Rails <= 8.0)' do
      node = Arel::Nodes::NamedFunction.new('coalesce', [expr])
      skip 'Arel::Nodes::NamedFunction#alias was removed in this Rails version' unless node.respond_to?(:alias)

      node.as('id_alias')
      visitor.accept(node)

      literals = visited.grep(Arel::Nodes::SqlLiteral).map(&:to_s)
      expect(literals).to include('id_alias')
    end
  end

  describe 'Arel::Nodes::Count' do
    it 'traverses the node without raising' do
      node = Arel::Nodes::Count.new([expr])

      expect { visitor.accept(node) }.not_to raise_error
      expect(visited).to include(expr)
    end
  end
end
