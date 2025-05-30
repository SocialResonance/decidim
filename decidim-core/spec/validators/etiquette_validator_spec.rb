# frozen_string_literal: true

require "spec_helper"

describe EtiquetteValidator do
  subject { validatable.new(body:) }

  let(:validatable) do
    Class.new do
      def self.model_name
        ActiveModel::Name.new(self, nil, "Validatable")
      end

      include Decidim::AttributeObject::Model
      include ActiveModel::Validations

      attribute :body

      validates :body, etiquette: true
    end
  end

  context "when the body is reasonable" do
    [
      %(I am a very reasonable body, ain't I? I have the right length, the right style, the right words. Yup.),
      %("Validate bodies", they said. "It is gonna be fun!", they said.),
      %(I contain special characters because I am à la mode.)
    ].each do |a_body|
      describe "like \"#{a_body}\"" do
        let(:body) { a_body }

        it "validates too much caps" do
          expect(subject).to be_valid
        end
      end
    end
  end

  context "when the text has too much caps" do
    let(:body) { "A SCREAMING PIECE of text" }

    context "when etiquette_validator is disabled" do
      before do
        allow(Decidim).to receive(:enable_etiquette_validator).and_return(false)
      end

      it { is_expected.to be_valid }
    end

    context "when etiquette_validator is enabled" do
      it { is_expected.to be_invalid }
    end
  end

  context "when the text has too many marks" do
    let(:body) { "I am screaming!!?" }

    it { is_expected.to be_invalid }
  end

  context "when the text has very long words" do
    context "and contains ascii chars" do
      let(:body) { "This word is veeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeery long." }

      it { is_expected.to be_valid }
    end

    context "and contains extended chars" do
      let(:body) { "This word is veeeeeeeeeeeeeeéeeeeeeeeeeeeeeeeeeeeery long." }

      it { is_expected.to be_valid }
    end

    context "and long words are links" do
      let(:body) { "This word is http://veeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeery.com https://veeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeery.com long." }

      it { is_expected.to be_valid }
    end
  end

  context "when the text is written starting in downcase" do
    context "with a single line body" do
      let(:body) { "i no care about grammar" }

      it { is_expected.to be_invalid }
    end

    context "with a multiple line body with the second line starting in downcase" do
      let(:body) { "This is a multiline body\nwith a line starting with downcase." }

      it { is_expected.to be_valid }
    end
  end

  context "when the text is written in HTML" do
    let(:body) do
      data = File.read(Decidim::Dev.asset("avatar.jpg"))
      encoded = Base64.encode64(data)

      <<~HTML
        <p>Text before the image.</p>
        <p><img src="data:image/jpeg;base64,#{encoded.strip}"></p>
        <p>Some other text after the image.</p>
      HTML
    end

    it { is_expected.to be_valid }
  end
end
