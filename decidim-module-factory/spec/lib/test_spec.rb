# frozen_string_literal: true

require "decidim/module_factory/generator"

module Decidim
  module ModuleFactory
    describe Generator do
      it "exists" do
        expect(described_class).to be_a(Class)
      end

      it "inherits from ComponentGenerator" do
        expect(described_class.superclass).to eq(Decidim::Generators::ComponentGenerator)
      end

      describe ".banner" do
        it "returns the correct banner text" do
          expect(described_class.banner).to eq("decidim-module-factory --module-factory NAME [options]")
        end
      end

      it "has the correct description" do
        # Thor stores the description in the class
        expect(described_class.tasks["component"].description).to eq("Generate a decidim component with AI rules")
      end
    end
  end
end
