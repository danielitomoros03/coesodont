# app/inputs/currency_input.rb
class CurrencyInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    "<div class='input-group'>#{@builder.text_field(attribute_name, merged_input_options)}<span class='input-group-text'>Bs.</span></div>".html_safe
  end
end