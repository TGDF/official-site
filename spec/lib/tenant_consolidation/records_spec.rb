# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TenantConsolidation::Records do
  describe '.translated_attributes' do
    it 'reads what the model declares with translates, STI subclasses included' do
      expect(described_class.translated_attributes('IndieSpace::Game')).to eq(%w[name description team])
    end

    it 'is empty for a model that translates nothing' do
      expect(described_class.translated_attributes('Slider')).to eq([])
    end
  end

  describe '.verify_translations_preserved' do
    let(:source) { { 'name' => { 'en' => 'Lumen', 'zh-TW' => '流明' } } }

    def written(name)
      Game.new.tap { |game| game[:name] = name }
    end

    it 'passes a row that kept every locale' do
      expect { described_class.verify_translations_preserved(source, written(source['name']), 'Game') }
        .not_to raise_error
    end

    it 'raises when a write lost a locale' do
      expect { described_class.verify_translations_preserved(source, written({ 'en' => 'Lumen' }), 'Game') }
        .to raise_error(/Translation loss detected for Game#\.name/)
    end
  end
end
