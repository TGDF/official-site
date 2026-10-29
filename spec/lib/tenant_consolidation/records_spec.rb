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

  describe '.verify_written_as_planned' do
    def write(attributes)
      Speaker.new.tap do |speaker|
        described_class.assign_raw_attributes(speaker, attributes)
        speaker.save!(validate: false)
      end
    end

    it 'passes a row saved exactly as written' do
      attributes = { 'name' => { 'zh-TW' => 'Ada' }, 'slug' => '12' }

      expect { described_class.verify_written_as_planned(attributes, write(attributes), 'Speaker') }.not_to raise_error
    end

    it 'raises when a callback rewrote a column on save' do
      attributes = { 'name' => { 'zh-TW' => 'Ada' }, 'slug' => nil }

      expect { described_class.verify_written_as_planned(attributes, write(attributes), 'Speaker') }
        .to raise_error(/Speaker#\d+\.slug was written as "ada", planned nil/)
    end
  end
end
