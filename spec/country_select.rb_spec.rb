require 'lib/country_select'

describe ActionView::Helpers::FormOptionsHelper do

  # Setup a fake helper for testing
  class CountrySelectSpecHelper
    # Use a limited set of countries for testing
    ActionView::Helpers::FormOptionsHelper::COUNTRIES = ["American Samoa", "Côte d'Ivoire", "Denmark", "Holy See (Vatican City State)"]
    include ActionView::Helpers::FormOptionsHelper
  end
  def helper
    @helper ||= CountrySelectSpecHelper.new
  end

  before :each do
    helper.stub!(:options_for_select).and_return('<option></option>')
    
    # Easier access to the countries we use for testing
    @countries = ActionView::Helpers::FormOptionsHelper::COUNTRIES
  end

  describe "countries" do
    it "should return the COUNTRIES array" do
      helper.countries.should == @countries
    end
  end

  describe "with I18n not available" do
    describe "translated_countries" do
      it "should return the original countries Array" do
        helper.translated_countries.should == @countries
      end
    end
  end

  describe "with I18n available" do
    before :each do
      # Pretend we have I18n available
      unless defined?(I18n)
        module I18n
          class MissingTranslationData < ArgumentError; end
        end
      end

      I18n.stub!(:translate).with(any_args()).and_raise(I18n::MissingTranslationData) # No translations for the 'en' language

      # Build an array of translations
      @translations = @countries.collect do |country|
        [country, country]
      end
    end
  
    describe "with locale set to 'en'" do
      describe "translated_countries" do
        it "should return the original countries Array" do
          helper.translated_countries.should == @translations
        end
      end
    
      describe "country_options_for_select" do
        it "should return a string" do
          helper.country_options_for_select.should be_instance_of(String)
        end

        it "should select the selected country" do
          helper.should_receive(:options_for_select).with(@translations, 'Denmark')
          result = helper.country_options_for_select('Denmark')
        end

        it "should return original values"

        describe "with priority countries" do
          it "should put priority countries at the top"
          it "should include a separator line"
        end
      
      end
    end

    describe "with locale set to 'da'" do
      before :each do
        @translations = [
          ["Amerikansk Samoa", "American Samoa"],
          ["Elfenbenskysten", "Côte d'Ivoire"],
          ["Danmark", "Denmark"],
          ["Den Hellige Stol (Vatikan Staten)", 'Holy See (Vatican City State)']
        ]        

        # Provide the translations through the backend
        @translations.each do |danish, english|
          I18n.stub!(:translate).with("countries.#{english}", :raise => true).and_return(danish)
        end
      end

      describe "translated_countries" do
        it "should return an Array with translated country names" do
          helper.translated_countries.should be_instance_of(Array)
        end

        it "should look up each translation in the backend" do
          @translations.each do |danish, english|
            I18n.should_receive(:translate).with("countries.#{english}", :raise => true)
          end
          helper.translated_countries
        end

        it "should use original value if translation isn't known" do
          # Don't fail when encountering the sovereign state of Petoria.
          helper.should_receive(:countries).and_return(['Petoria'])
          I18n.should_receive(:translate).with("countries.Petoria", :raise => true).and_raise(I18n::MissingTranslationData)
          helper.translated_countries.should == [['Petoria', 'Petoria']]
        end
      end
    
      describe "translate_countries" do
        it "should return an Array with translated country names" do
          helper.translate_countries([]).should be_instance_of(Array)
        end

        it "should look up each translation in the backend" do
          @translations.each do |danish, english|
            I18n.should_receive(:translate).with("countries.#{english}", :raise => true)
          end
          helper.translate_countries(@translations.collect { |danish, english| english })
        end

        it "should use original value if translation isn't known" do
          # Don't fail when encountering the sovereign state of Petoria.
          I18n.should_receive(:translate).with("countries.Petoria", :raise => true).and_raise(I18n::MissingTranslationData)
          helper.translate_countries(['Petoria']).should == [['Petoria', 'Petoria']]
        end
      end
    
      describe "country_options_for_select" do

        it "should select the selected country" do
          helper.should_receive(:options_for_select).with(@translations, 'Denmark')
          result = helper.country_options_for_select('Denmark')
        end

        it "should use translated values" do
          helper.should_receive(:options_for_select).with(@translations, nil)
          helper.country_options_for_select
        end

        it "should translate priority countries" do
          helper.should_receive(:options_for_select).with([['Danmark', 'Denmark']], nil)
          result = helper.country_options_for_select(nil, ['Denmark'])
        end

      end
    end
  end
end