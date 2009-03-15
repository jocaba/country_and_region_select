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
        helper.send(:translated_countries).should == @countries
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
        it "should return the default translations" do
          helper.send(:translated_countries).should == @translations
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

        describe "with priority countries" do
          it "should put priority countries at the top" do
            helper.should_receive(:options_for_select).with([['Denmark', 'Denmark']], 'Ireland')
            helper.should_receive(:options_for_select).with(@translations, 'Ireland')
            result = helper.country_options_for_select('Ireland', ['Denmark'])
          end

          it "should include a separator line" do
            helper.country_options_for_select('Ireland', ['Denmark']).should match(/<option value="" disabled="disabled">-+<\/option>/)
          end
        end
      end
    end

    describe "with locale set to 'da'" do
      before :each do
        @translations = [
          ["Amerikansk Samoa", "American Samoa"],
          ["Danmark", "Denmark"],
          ["Den Hellige Stol (Vatikan Staten)", 'Holy See (Vatican City State)'],
          ["Elfenbenskysten", "Côte d'Ivoire"]
        ]

        # Provide the translations through the backend
        @translations.each do |danish, english|
          I18n.stub!(:translate).with(english, :scope => 'countries', :raise => true).and_return(danish)
        end
      end

      describe "translated_countries" do
        it "should return an Array with translated country names" do
          helper.send(:translated_countries).should be_instance_of(Array)
        end

        it "should sort the translated values" do
          @result = ['']
          helper.should_receive(:translate_countries).and_return(@result)
          @result.should_receive(:sort)
          helper.send(:translated_countries)
        end
        
        it "should look up each translation in the backend" do
          @translations.each do |danish, english|
            I18n.should_receive(:translate).with(english, :scope => 'countries', :raise => true)
          end
          helper.send(:translated_countries)
        end

        it "should use original value if translation isn't known" do
          # Don't fail when encountering the sovereign state of Petoria.
          helper.should_receive(:countries).and_return(['Petoria'])
          I18n.should_receive(:translate).with("Petoria", :scope => 'countries', :raise => true).and_raise(I18n::MissingTranslationData)
          helper.send(:translated_countries).should == [['Petoria', 'Petoria']]
        end
      end
    
      describe "translate_countries" do
        it "should return an Array with translated country names" do
          helper.send(:translate_countries, []).should be_instance_of(Array)
        end

        it "should look up each translation in the backend" do
          @translations.each do |danish, english|
            I18n.should_receive(:translate).with(english, :scope => 'countries', :raise => true)
          end
          helper.send(:translate_countries, @translations.collect { |danish, english| english })
        end

        it "should use original value if translation isn't known" do
          # Don't fail when encountering the sovereign state of Petoria.
          I18n.should_receive(:translate).with("Petoria", :scope => 'countries', :raise => true).and_raise(I18n::MissingTranslationData)
          helper.send(:translate_countries, ['Petoria']).should == [['Petoria', 'Petoria']]
        end
      end
    
      describe "country_options_for_select" do

        it "should select the selected country" do
          helper.should_receive(:options_for_select).with(@translations, 'Denmark')
          result = helper.country_options_for_select('Denmark')
        end

        it "should sort the big list of countries" do
          helper.send(:translate_countries, ['Petoria', 'American Samoa', 'Denmark']).should == [
            ['Amerikansk Samoa', 'American Samoa'],
            ['Danmark', 'Denmark'],
            ['Petoria', 'Petoria']
          ]
        end

        describe "with priority countries" do
          it "should put priority countries at the top" do
            helper.should_receive(:options_for_select).with([['Danmark', 'Denmark']], 'Ireland')
            helper.should_receive(:options_for_select).with(@translations, 'Ireland')
            result = helper.country_options_for_select('Ireland', ['Denmark'])
          end

          it "should include a separator line" do
            helper.country_options_for_select('Ireland', ['Denmark']).should match(/<option value="" disabled="disabled">-+<\/option>/)
          end

          it "should translate priority countries" do
            helper.should_receive(:options_for_select).with([['Danmark', 'Denmark']], nil)
            result = helper.country_options_for_select(nil, ['Denmark'])
          end
        end
      end
    end
  end
end