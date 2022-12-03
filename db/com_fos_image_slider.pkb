create or replace package body com_fos_image_slider
as

-- =============================================================================
--
--  FOS = FOEX Open Source (fos.world), by FOEX GmbH, Austria (www.foex.at)
--
--  This plug-in lets you easily create different types of image sliders with
--  options like autosliding, descriptionboxes, pagination, navigation,
--  thumbs gallery, vertical and horizontal sliders.
--
--  License: MIT
--
--  GitHub: https://github.com/foex-open-source/fos-image-slider
--
--
-- =============================================================================

-- procedure to pass data to the frontend
procedure htpclob
  ( p_clob in out nocopy clob
  )
is
    l_chunk varchar2(32000);
    l_clob  clob := p_clob;
begin
    while length(l_clob) > 0
    loop
        begin
            if length(l_clob) > 16000
            then
                l_chunk := substr(l_clob,1,16000);
                sys.htp.prn(l_chunk);
                l_clob := substr(l_clob,length(l_chunk)+1);
            else
                l_chunk := l_clob;
                sys.htp.prn(l_chunk);
                l_clob := '';
                l_chunk := '';
            end if;
        end;
    end loop;
end htpclob;

function render
  ( p_region              in apex_plugin.t_region
  , p_plugin              in apex_plugin.t_plugin
  , p_is_printer_friendly in boolean
  )
return apex_plugin.t_region_render_result
as
    l_result                  apex_plugin.t_region_render_result;
    l_ajax_id                 varchar2(4000)             := apex_plugin.get_ajax_identifier;
    l_region_id               p_region.static_id%type    := nvl(p_region.static_id, p_region.id);
    l_source                  p_region.source%type       := p_region.source;
    l_init_js                 varchar2(32767)            := nvl(apex_plugin_util.replace_substitutions(p_region.init_javascript_code), 'undefined');
    l_items_to_submit         varchar2(32767)            := p_region.ajax_items_to_submit;   

    l_source_type             p_region.attribute_01%type := p_region.attribute_01;
    l_col_src_pr_key          p_region.attribute_02%type := p_region.attribute_02;
    l_col_src_blob            p_region.attribute_03%type := p_region.attribute_03;
    l_col_src_mime_type       p_region.attribute_04%type := p_region.attribute_04;
    l_col_src_file_name       p_region.attribute_05%type := p_region.attribute_05;

    l_col_src_url             p_region.attribute_06%type := p_region.attribute_06;

    l_direction               p_region.attribute_07%type := p_region.attribute_07;
    l_image_size              p_region.attribute_08%type := p_region.attribute_08;
    l_image_size_custom       p_region.attribute_09%type := p_region.attribute_09;
    l_delay_time              pls_integer                := to_number(p_region.attribute_11);
    l_ipr_attr                pls_integer                := round(to_number(p_region.attribute_12));
    l_images_per_region       pls_integer                := case when l_ipr_attr < 1 then 1 else l_ipr_attr end;
    l_transition_single_img   p_region.attribute_10%type := p_region.attribute_13;
    l_transition_multi_img    p_region.attribute_11%type := p_region.attribute_14;

    l_options                 p_region.attribute_07%type := p_region.attribute_10;

    l_pagination              boolean                    := instr(l_options, 'pagination'              ) > 0;
    l_navigation              boolean                    := instr(l_options, 'navigation'              ) > 0;
    l_autoplay                boolean                    := instr(l_options, 'autoplay'                ) > 0;
    l_desc_box                boolean                    := instr(l_options, 'description-box'         ) > 0;
    l_loop_mode               boolean                    := instr(l_options, 'loop'                    ) > 0;
    l_thumbnail               boolean                    := instr(l_options, 'display-thumbnails'      ) > 0;
    l_fullscreen_mode         boolean                    := instr(l_options, 'fullscreen-support'      ) > 0;
    l_hide_navigation         boolean                    := instr(l_options, 'navigation-hide-on-click') > 0;
    l_hide_pagination         boolean                    := instr(l_options, 'pagination-hide-on-click') > 0;
    l_pause_on_mouse_enter    boolean                    := instr(l_options, 'pause-on-mouse-enter'    ) > 0;
    l_transition              varchar2(255)              := case when l_images_per_region = 1 then l_transition_single_img else l_transition_multi_img end;

    l_img_pr_key_val          varchar2(32000);
    l_img_pr_key_pos          pls_integer;
    l_img_url                 pls_integer;
    l_img_title               pls_integer;
    l_img_subtitle            pls_integer;
    l_img_description         pls_integer;
    l_img_buttonurl           pls_integer;
    l_img_buttonlabel         pls_integer;
    l_img_data_slide          pls_integer;

    c_plugin_css_prefix       constant varchar2(100)     := 'fos-image-slider';
    l_image_url               varchar2(32000);
    l_context                 apex_exec.t_context;
    l_url_val                 varchar2(32767);
    l_items_thumbnail_html    clob;

    procedure print_desc_box
    as
        l_title_val               varchar2(32767) := apex_exec.get_varchar2(l_context, l_img_title      );
        l_subtitle_val            varchar2(32767) := apex_exec.get_varchar2(l_context, l_img_subtitle   );
        l_description_val         varchar2(32767) := apex_exec.get_varchar2(l_context, l_img_description);
        l_buttonurl_val           varchar2(32767) := apex_exec.get_varchar2(l_context, l_img_buttonurl  );
        l_buttonlabel_val         varchar2(32767) := apex_exec.get_varchar2(l_context, l_img_buttonlabel);
        l_data_slide_val          varchar2(32767) := case when l_img_data_slide is not null then apex_exec.get_varchar2(l_context, l_img_data_slide ) else '' end;
    begin
        sys.htp.p('<div class="'||c_plugin_css_prefix||'-box" data-slide="'|| l_data_slide_val ||'">'); -- box

        if l_title_val is not null or l_subtitle_val is not null then
            sys.htp.p('<div class="'||c_plugin_css_prefix||'-box-header">'); -- header
        end if;

        if l_title_val is not null then
            sys.htp.p('    <div class="'||c_plugin_css_prefix||'-box-title">' || l_title_val || '</div>'); -- title    open&close
        end if;
        if l_subtitle_val is not null then
            sys.htp.p('    <div class="'||c_plugin_css_prefix||'-box-subtitle">' || l_subtitle_val || '</div>'); -- subtitle open&close
        end if;

        if l_title_val is not null or l_subtitle_val is not null then
            sys.htp.p('</div>'); -- close header
        end if;

        sys.htp.p('    <div class="'||c_plugin_css_prefix||'-box-text">'); -- text
        sys.htp.p('        <p>' || l_description_val || '</p>');
        sys.htp.p('    </div>'); -- close text

        -- do not render the footer with the button if there is no URL
        if l_buttonurl_val is not null then
            sys.htp.p('<div class="'||c_plugin_css_prefix||'-box-footer">'); -- footer
            sys.htp.p('    <div class="'||c_plugin_css_prefix||'-box-button-wrapper">'); -- button wrapper
            sys.htp.p('        <div class="'||c_plugin_css_prefix||'-box-button">'); -- button box
            sys.htp.p('             <a href="' || l_buttonurl_val || '" target="_blank" class="'||c_plugin_css_prefix||'-box-button-title">' || l_buttonlabel_val || '</a>');
            sys.htp.p('        </div>'); -- button box close
            sys.htp.p('    </div>'); -- button wrapper close
            sys.htp.p('</div>'); -- close footer
        end if;

        sys.htp.p('</div>'); -- close box
    end print_desc_box;

begin
    --debug
    if apex_application.g_debug and substr(:DEBUG,6) >= 6
    then
        apex_plugin_util.debug_region
            ( p_plugin => p_plugin
            , p_region => p_region
            );
    end if;

    apex_debug.message('region source -> %s', l_source);

    --execute image query
    l_context := apex_exec.open_query_context
        ( p_location        => apex_exec.c_location_local_db
        , p_sql_query       => l_source
        , p_total_row_count => true
        );

    if l_source_type = 'url'
    then
        l_img_url:= apex_exec.get_column_position(l_context, l_col_src_url);
    else
        l_img_pr_key_pos := apex_exec.get_column_position(l_context, l_col_src_pr_key);
        l_image_url := 'wwv_flow.show?p_flow_id='|| v('APP_ID')
                            ||'&p_flow_step_id='||v('APP_PAGE_ID')
                            ||'&p_instance='||v('APP_SESSION')
                            ||'&p_debug='||CASE apex_application.g_debug WHEN TRUE THEN 'YES' ELSE 'NO' END
                            ||'&p_request=PLUGIN='||l_ajax_id
                            ||'&p_widget_action=DISPLAY_IMAGE';
    end if;

    if l_desc_box then
        l_img_title         := apex_exec.get_column_position(l_context, 'TITLE'      );
        l_img_subtitle      := apex_exec.get_column_position(l_context, 'SUBTITLE'   );
        l_img_description   := apex_exec.get_column_position(l_context, 'DESCRIPTION');
        l_img_buttonurl     := apex_exec.get_column_position(l_context, 'BUTTONURL'  );
        l_img_buttonlabel   := apex_exec.get_column_position(l_context, 'BUTTONLABEL');
        if instr(l_source, 'DATA_SLIDE') > 0
        then
            l_img_data_slide    := apex_exec.get_column_position(l_context, 'DATA_SLIDE' );
        end if;
    end if;

    -- region container
    sys.htp.p('<div class="'||c_plugin_css_prefix||'-container">');

    --
    sys.htp.p('<div class="swiper-container '||c_plugin_css_prefix||'-gallery">');

    --fullscreen
    if l_fullscreen_mode then
       sys.htp.p('<div class="'||c_plugin_css_prefix||'-fullscreen-btn" role="button">');
       sys.htp.p('  <div class="fa fa-expand"></div>');
       sys.htp.p('</div>');
    end if;

    -- slider main container
    sys.htp.p('<div class="swiper-wrapper">');

    while apex_exec.next_row(l_context)
    loop
        -- the source of the image
        if l_source_type = 'url'
        then
            l_url_val := apex_exec.get_varchar2(l_context, l_img_url);
        else
            l_img_pr_key_val := apex_exec.get_varchar2(l_context, l_img_pr_key_pos);
            l_url_val := l_image_url || '&x01='||l_img_pr_key_val;
        end if;

        -- slides
        sys.htp.p('<div class="swiper-slide swiper-lazy" data-background="'|| l_url_val   ||'">');
        -- preloader spinner
        sys.htp.p('    <div class="swiper-lazy-preloader"></div>');
        -- description box
        if l_desc_box then
            print_desc_box;
        end if;
        -- enclose slide
        sys.htp.p('</div>');

        --thumbnail
        if l_thumbnail then
            l_items_thumbnail_html := l_items_thumbnail_html || '<div class="swiper-slide '||c_plugin_css_prefix||'-thumbnail-slide" style="background-image:url('|| l_url_val || ')"></div>';
        end if;

    end loop;

    -- slider main container close
    sys.htp.p('</div>');

    --pagination
    if l_pagination then
       sys.htp.p('<div class="swiper-pagination swiper-pagination-bullets"></div>');
    end if;

    --switchers
    if l_navigation then
       sys.htp.p('<div class="swiper-button-next u-hot"></div>');
       sys.htp.p('<div class="swiper-button-prev u-hot"></div>');
    end if;

    --container close
    sys.htp.p('</div>');

    --thumbnails
    if l_thumbnail then
        sys.htp.p('<div class="swiper-container '||c_plugin_css_prefix||'-thumbnails">');
        sys.htp.p('    <div class="swiper-wrapper">');
        htpclob(         l_items_thumbnail_html);
        sys.htp.p('    </div>');
        sys.htp.p('</div>');
    end if;

    sys.htp.p('</div>');

    --creating json
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write('regionId'               , to_char(l_region_id)         );
    apex_json.write('thumbnailsEnabled'      , l_thumbnail                  );
    apex_json.write('navigation'             , l_navigation                 );
    apex_json.write('loop'                   , l_loop_mode                  );
    apex_json.write('autoplay'               , l_autoplay                   );
    apex_json.write('delaySecs'              , l_delay_time                 );
    apex_json.write('imagesPerRegion'        , l_images_per_region          );
    apex_json.write('descriptionBox'         , l_desc_box                   );
    apex_json.write('transition'             , l_transition                 );
    apex_json.write('direction'              , l_direction                  );
    apex_json.write('pagination'             , l_pagination                 );
    apex_json.write('imageSize'              , l_image_size                 );
    apex_json.write('imageSizeCustom'        , l_image_size_custom          );
    apex_json.write('fullscreenSupport'      , l_fullscreen_mode            );
    apex_json.write('hideNavigationOnClick'  , l_hide_navigation            );
    apex_json.write('hidePaginationOnClick'  , l_hide_pagination            );
    apex_json.write('pauseOnMouseEnter'      , l_pause_on_mouse_enter       );
    apex_json.write('pageItemsToSubmit'      , l_items_to_submit            );
    apex_json.write('pluginUri'              , l_ajax_id                    );
    --
    apex_json.write('requestType'            , 'REFRESH'                    );
    
    --closing the query context
    apex_exec.close(l_context);

    apex_json.close_object;

    --onload code
    apex_javascript.add_onload_code(p_code => 'FOS.region.imageSlider.initSlider(' || apex_json.get_clob_output || ', '|| l_init_js ||');');

    apex_json.free_output;

    return l_result;

end render;

procedure ajax_blob
  ( p_region in apex_plugin.t_region
  , p_plugin in apex_plugin.t_plugin
  )
as
    l_ajax_id                 varchar2(4000)             := apex_plugin.get_ajax_identifier;
    l_region_id               p_region.static_id%type    := nvl(p_region.static_id, p_region.id);
    l_source                  p_region.source%type       := p_region.source;

    l_col_src_pr_key          p_region.attribute_02%type := p_region.attribute_02;
    l_col_src_blob            p_region.attribute_03%type := p_region.attribute_03;
    l_col_src_mime_type       p_region.attribute_04%type := p_region.attribute_04;
    l_col_src_file_name       p_region.attribute_05%type := p_region.attribute_05;


    l_img_pr_key_pos          pls_integer;
    l_img_mime_type           pls_integer;
    l_img_file_name           pls_integer;
    l_img_blob                pls_integer;

    l_img_pr_key_val          varchar2(32000);
    l_img_mime_type_val       varchar2(32000);
    l_img_file_name_val       varchar2(32000);
    l_img_blob_val            blob;

    l_context                 apex_exec.t_context;
    l_filters                 apex_exec.t_filters;
    l_img_pr_key              varchar2(32000) := apex_application.g_x01;

    l_file_size   pls_integer;
begin

    -- add filter on the primary key(using the value from the request)
    apex_exec.add_filter
        ( p_filters     => l_filters
        , p_filter_type => apex_exec.c_filter_eq
        , p_column_name => l_col_src_pr_key
        , p_value       => l_img_pr_key
        );

    -- open the context
    l_context := apex_exec.open_query_context
        ( p_location        => apex_exec.c_location_local_db
        , p_sql_query       => l_source
        , p_filters         => l_filters
        , p_total_row_count => true
        );

    -- get the column positions
    l_img_mime_type := apex_exec.get_column_position(l_context, l_col_src_mime_type);
    l_img_file_name := apex_exec.get_column_position(l_context, l_col_src_file_name);
    -- the default data_type is varchar2, so we have to set it to blob
    l_img_blob      := apex_exec.get_column_position
        ( p_context => l_context
        , p_column_name => l_col_src_blob
        , p_data_type => apex_exec.c_data_type_blob
        );

    while apex_exec.next_row(l_context)
    loop
        -- get the value from the specified columns
        l_img_mime_type_val := apex_exec.get_varchar2(l_context,l_img_mime_type);
        l_img_file_name_val := apex_exec.get_varchar2(l_context,l_img_file_name);
        l_img_blob_val       := apex_exec.get_blob(l_context,l_img_blob);
    end loop;

    apex_exec.close(l_context);

    -- get the length of the blob
    l_file_size := dbms_lob.getlength(l_img_blob_val);

    -- create the header
    owa_util.mime_header(l_img_mime_type_val);
    sys.htp.p('Content-length: '||l_file_size);
    sys.htp.p('Content-Disposition: inline; filename="'||l_img_file_name||'"');
    owa_util.http_header_close;

    -- download the file
    wpg_docload.download_file(l_img_blob_val);
end ajax_blob;

procedure fetch_urls
  ( p_region in apex_plugin.t_region
  , p_plugin in apex_plugin.t_plugin
  )
as
	l_ajax_id                 varchar2(4000)        := apex_plugin.get_ajax_identifier;
	l_source                  p_region.source%type  := p_region.source;

	l_source_type             p_region.attribute_01%type := p_region.attribute_01;
	l_col_src_pr_key          p_region.attribute_02%type := p_region.attribute_02;
	l_col_src_blob            p_region.attribute_03%type := p_region.attribute_03;
    l_col_src_url             p_region.attribute_06%type := p_region.attribute_06;
	
	l_context               apex_exec.t_context;
    l_img_url_pos           pls_integer;
	l_img_pr_key_pos        pls_integer;

	l_img_pr_key_val        varchar2(32000);

	l_base_image_url        constant varchar2(32000) := 
		'wwv_flow.show?p_flow_id='|| v('APP_ID')
		||'&p_flow_step_id='||v('APP_PAGE_ID')
		||'&p_instance='||v('APP_SESSION')
		||'&p_debug='||CASE apex_application.g_debug WHEN TRUE THEN 'YES' ELSE 'NO' END
		||'&p_request=PLUGIN='||apex_plugin.get_ajax_identifier
		||'&p_widget_action=DISPLAY_IMAGE'
	;
begin
    --execute the query
    l_context := apex_exec.open_query_context
        ( p_location        => apex_exec.c_location_local_db
        , p_sql_query       => l_source
        , p_total_row_count => true
        );

	if l_source_type = 'url'
	then
		l_img_url_pos:= apex_exec.get_column_position(l_context, l_col_src_url);
	else
		l_img_pr_key_pos := apex_exec.get_column_position(l_context, l_col_src_pr_key);
	end if;

    -- creating the JSON
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.open_array('result');
	
    while apex_exec.next_row(l_context)
    loop
		if l_source_type = 'url'
		then
			apex_json.write(apex_exec.get_varchar2(l_context, l_img_url_pos));
		else
			l_img_pr_key_val := apex_exec.get_varchar2(l_context, l_img_pr_key_pos);
			apex_json.write(l_base_image_url || '&x01='||l_img_pr_key_val);
		end if;
    end loop;
    apex_json.close_array;
    apex_json.close_object;

    --closing the query context
    apex_exec.close(l_context);
    
    -- send it back to the frontend
    sys.htp.p(apex_json.get_clob_output);

    apex_json.free_output;

end fetch_urls;

function ajax
  ( p_region in apex_plugin.t_region
  , p_plugin in apex_plugin.t_plugin
  )
return apex_plugin.t_region_ajax_result
as
    l_result        apex_plugin.t_region_ajax_result;
    l_request_type  varchar2(32000) := apex_application.g_x02;
begin

    -- standard debugging
    if apex_application.g_debug and substr(:DEBUG,6) >= 6
    then
        apex_plugin_util.debug_region
          ( p_plugin  => p_plugin
          , p_region  => p_region
          );
    end if;

    if l_request_type = 'REFRESH'
    then
        fetch_urls
        ( p_region => p_region
        , p_plugin => p_plugin
        );
    else
        ajax_blob
        ( p_region => p_region
        , p_plugin => p_plugin
        );
    end if;

    return l_result;

end ajax;

end;
/


