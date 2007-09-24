
class Gruff::Base
  
  def draw_legend
    @legend_labels = @data.collect {|item| item[DATA_LABEL_INDEX] }

    legend_square_width = @legend_box_size # small square with color of this item
    legend_left = 10

    current_x_offset = legend_left
    current_y_offset =  TOP_MARGIN + TITLE_MARGIN + @title_caps_height + LEGEND_MARGIN

    debug { @d.line 0.0, current_y_offset, @raw_columns, current_y_offset }
                                                  
    @legend_labels.each_with_index do |legend_label, index|      

      next if index > MAX_LEGENDS
      legend_label = "some not shown" if index == MAX_LEGENDS

      # Draw label
      @d.fill = @font_color
      @d.font = @font if @font
      @d.pointsize = scale_fontsize(@legend_font_size)
      @d.stroke('transparent')
      @d.font_weight = NormalWeight
      @d.gravity = WestGravity
      @d = @d.annotate_scaled( @base_image, 
                        @raw_columns, 1.0,
                        current_x_offset + (legend_square_width * 1.7), current_y_offset, 
                        legend_label.to_s, @scale)
      
      if index < MAX_LEGENDS
      # Now draw box with color of this dataset
        @d = @d.stroke('transparent')
        @d = @d.fill @data[index][DATA_COLOR_INDEX]
        @d = @d.rectangle(current_x_offset, 
                          current_y_offset - legend_square_width / 2.0, 
                          current_x_offset + legend_square_width, 
                          current_y_offset + legend_square_width / 2.0)
      end

      @d.pointsize = @legend_font_size
      metrics = @d.get_type_metrics(@base_image, legend_label.to_s)
      current_y_offset += metrics.height * 1.05
    end
    @color_index = 0
  end
  
  alias :setup_graph_measurements_without_top_margin :setup_graph_measurements
  def setup_graph_measurements  
    setup_graph_measurements_without_top_margin
    @graph_height += NEGATIVE_TOP_MARGIN
    @graph_top -= NEGATIVE_TOP_MARGIN    
  end
  
  alias :clip_value_if_greater_than_without_size_hacks :clip_value_if_greater_than
  def clip_value_if_greater_than(arg1, arg2)
     arg2 = arg2 / 2 if arg1 == @columns / (@norm_data.first[1].size * 2.5)
     clip_value_if_greater_than_without_size_hacks(arg1, arg2)
  end
  
end
