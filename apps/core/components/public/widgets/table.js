Spider.defineWidget('Spider.Components.Table', {
	
	autoInit: true,
	
	ready: function(){
      if(typeof(this.el)!="undefined") {
      var isResponsive = $('ul.table:not(.no-responsive)', this.el).length>0;
      if(!isResponsive) {
        $('.pagination-mobile-loadmore', this.el).remove();
        $('.pagination-mobile-reset', this.el).remove();
        $('.mobile-sorting', this.el).remove();
      }
      this.ajaxify($('.heading_row a, .pagination a, .pagination-mobile-reset a, .mobile-sorting a', this.el));
      var $table = $('ul.table', this.el);
      
      if(isResponsive) {
        $loadMore = $('.pagination-mobile-loadmore', this.el);
        $loadMore.on('click', 'a', function(e) {
            e.preventDefault();
            var a = $(e.target);
            a.parent().html('<i class=\"fa fa-circle-o-notch fa-spin fa-3x fa-fw muted\"></i><span class=\"sr-only\">Caricamento...</span>');

            $.get(a.attr('href'), function( data ) {
              var $loadedTable = $(data).find("#"+$table.attr("id"));
              if($loadedTable.length<1) {
                $loadedTable = $(data).find("table:not(.no-responsive)").eq($table.attr("id").replace("table_","")).parent();
              }
              var columns = [];
              $table.find('.table-header div').each(function(){
                columns.push($(this).text());
              });
              $table.find("ul.table li").not('.table-header').remove();
              var largestCol = rowsToLi($loadedTable.find('tbody'), $table, columns);
              setCellWidths(largestCol, columns, $table);
              if($loadedTable.find('.pagination-mobile-loadmore a').length>0) {
                $('.pagination-mobile-loadmore').html($loadedTable.find('.pagination-mobile-loadmore').html());
              } else {
                $('.pagination-mobile-loadmore').addClass("muted").html("Non ci sono altri risultati.");
              }
              if($loadedTable.find('.mobile-sorting').length>0) {
                $('.mobile-sorting').html($loadedTable.find('.mobile-sorting').html());
              }
            });
            return true;
        });
      }
      }
	}

});
