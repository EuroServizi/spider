/* PAGINATORE JS V 2 */
/*  campi hidden da avere nella pagina dove si vuole usare il paginatore
        Imposto il numero di righe per pagina che viene passato al js
        <input type='hidden' id='items_per_page' value="10" />  

        Imposto il numero di link di pagine da mostrare nella navbar 
        <input type='hidden' id='max_page_in_navbar' value="14"/>

        Campi usati dalle funzioni del paginatore
        <input type='hidden' id='current_page' />
        <input type='hidden' id='show_per_page' />

    stili per tabella con paginazione (sono in admin.scss)
        
        :not(.spider.components.table){
           .page_navigation{
                &.pagination{
                    display: inline-block;
                    margin-bottom: 10px;
                    margin-left: 20px;
                
                    .active_page{
                        font-size: 120%;
                        font-weight: 700;
                    }
                    ul.lista_pagine{
                        list-style: none;
                        overflow: hidden;
                        display: none;
                    }

                    .active a {
                        font-size: 120%;
                        font-weight: 700;
                        cursor: default;
                    }
                    
                    li.previous_link, li.next_link{
                        border-left-width: 1px;
                        border-radius: 3px 0 0 3px;
                    }
                    
                }
            }

            selettore delle pagine, fatto con dropup bootstrap 3
            .sel_pagine{
                display: inline-block;
                margin-bottom: 5px;
                margin-left: 20px;
                button{
                    color: #049cdb;
                }
                .dropdown-menu{
                    min-width: 30px;
                    &.lista_pagine{
                        max-height: 300px;
                        overflow-y: scroll; 
                    }
                }
            } 
        }


    Esempio di uso
        <table class="pagination_content">  -> indica che questo elemento sarà il contenitore
            <tbody>
                <tr class="paginated_element"> -> elemento conteggiato per la paginazione
                    <td>.....
                </tr>
            .....
        </table>
        <div class="page_navigation pagination"><ul></ul></div>  -> dopo il pagination_content serve un page_navigation per la barra di navigazione


    Nel javascript per abilitare il paginatore bisogna richiamare la funzione 
    init_paginatore();
    Se si vuole limitarlo ad una porzione di dom (uno scope) ad esempio: <div id="elemento_paginatore" >..</div> , si usa
    init_paginatore("#elemento_paginatore");


*/






/* il parametro scope limita il funzionamento ad un pezzo della pagina, serve per avere più paginatori nella pagina */

/* porta alla prima pagina, usato nel bottone << */
function first_page(scope){
    if (scope === undefined) {
          scope = 'body';
    } 
    go_to_page(1, scope);
};

/* porta alla pagina precedente, usato nel bottone < */
function previous(scope){
    if (scope === undefined) {
          scope = 'body';
    } 
    new_page = parseInt($(scope).find('#current_page').val())-1;
    /* if there is an item before the current active link run the function */
    if($(scope).find('.active').prev('.page_link').length==true){
        go_to_page(new_page, scope);
    }

};

/* porta alla pagina successiva, usato nel bottone > */
function next(scope){
    if (scope === undefined) {
          scope = 'body';
    }
    new_page = parseInt($(scope).find('#current_page').val())+1;
    /*if there is an item after the current active link run the function */
    if($(scope).find('.active').next('.page_link').length==true){
        go_to_page(new_page, scope);
    }

};

/* porta ll'ultima pagina, usato nel bottone >> */
function last_page(scope){
    if (scope === undefined) {
          scope = 'body';
    }
    /* dato il numero di pagine e il num pagine da mostrare */
    var show_per_page = parseInt($(scope).find("#items_per_page").val());
    var number_of_items = parseInt($(scope).find('.pagination_content .paginated_element').size());
    /*calculate the number of pages we are going to have*/
    var number_of_pages = Math.ceil(number_of_items/show_per_page);
    go_to_page(number_of_pages, scope);

};

/* porta alla pagina page_num, limitata allo scope passato per avere più paginatori in una pagina */
function go_to_page(page_num, scope){
    if (scope === undefined) {
          scope = 'body';
    }

    /*get the number of items shown per page*/
    var show_per_page = parseInt($(scope).find('#show_per_page').val());

    /*get the element number where to start the slice from*/
    start_from = (page_num-1) * show_per_page;

    /*get the element number where to end the slice*/
    end_on = start_from + show_per_page;

    /*hide all children elements of pagination_content div, get specific items and show them*/
    $(scope).find('.pagination_content .paginated_element').hide().slice(start_from, end_on).show();

    /*get the page link that has longdesc attribute of the current page and add active class to it
    and remove that class from previously active page link*/
    $(scope).find('.page_link.active').removeClass('active');

    /* numero di pagine nella navigation bar */
    var max_page_in_navbar = parseInt($(scope).find("#max_page_in_navbar").val());
    /*getting the amount of elements inside pagination_content div*/
    var number_of_items = parseInt($(scope).find('.pagination_content .paginated_element').size());
    /*calculate the number of pages we are going to have*/
    var number_of_pages = Math.ceil(number_of_items/show_per_page);

    /*update the current page input field*/
    $(scope).find('#current_page').val(page_num);

    /* svuoto il selettore delle pagine e lo ricreo mostrando il numero di pagina */
    $(scope).find(".sel_pagine").empty();

    if(number_of_pages>max_page_in_navbar){
        /* su la pag corrente è maggiore del numero di pagine - metà delle pagine mostrate nella navbar non traslo più le pagine, le sto già vedendo tutte le restanti */
        if(page_num >= (number_of_pages-Math.floor(parseInt(max_page_in_navbar)/2)))
        {
            var window_width = $( window ).width();
            var classi_paginatore = "pagination";
            if(window_width <= 768){
                classi_paginatore += " pagination-lg";
            }
            /* svuoto la lista di pagine */ 
            $(scope).find(".page_navigation").empty();
            var navigation_html = "<ul class='"+classi_paginatore+"'><li class=\"previous_link\"><a href=\"javascript:first_page('"+scope+"');\"> << </a></li>";
            navigation_html += "<li><a href=\"javascript:previous('"+scope+"');\"> < </a></li>";
            if(page_num>=(Math.floor(parseInt(max_page_in_navbar)/2)+1) ){
                navigation_html += "<li class=\"page_link\" longdesc=\"...\"><a href=\"javascript:go_to_page("+( (number_of_pages-max_page_in_navbar)-1 )+", '" + scope + "')\">...</a></li>";
            }
            for (i=number_of_pages-max_page_in_navbar; i<=number_of_pages; i++){

                navigation_html += "<li class=\"page_link\" longdesc=\"" + i +"\"><a href=\"javascript:go_to_page(" + i +", '" + scope + "')\" >"+ (i) +"</a></li>";
            }
            navigation_html += "<li><a href=\"javascript:next('"+scope+"');\"> > </a></li>";
            navigation_html += "<li class=\"next_link\"><a href=\"javascript:last_page('"+scope+"');\"> >> </a></li>";
            $(scope).find('.page_navigation').html(navigation_html);
            
        }
        else
        /* traslo le pagine */
        {
            var current_link = (page_num-Math.floor(max_page_in_navbar/2));
            if(current_link<=1){
               current_link = 1; 
            }
            /* svuoto la lista di pagine */ 
            $(scope).find(".page_navigation").empty();
            var navigation_html = "<li class=\"previous_link\"><a href=\"javascript:first_page('"+scope+"');\"> << </a></li>";
            navigation_html += "<li><a href=\"javascript:previous('"+scope+"');\"> < </a></li>";
            if(page_num>=(Math.floor(parseInt(max_page_in_navbar)/2)+1) ){
                navigation_html += "<li class=\"page_link\" longdesc=\"...\"><a href=\"javascript:go_to_page("+( page_num-(Math.floor(parseInt(max_page_in_navbar)/2)+1) )+", '" + scope + "')\">...</a></li>";
            }
            for (i=current_link; i<=(current_link+max_page_in_navbar); i++){
                navigation_html += "<li class=\"page_link\" longdesc=\"" + i +"\"><a href=\"javascript:go_to_page(" + i +", '" + scope + "')\" >"+ (i) +"</a></li>";
            }
            navigation_html += "<li class=\"page_link\" longdesc=\"...\"><a href=\"javascript:go_to_page("+i+", '" + scope + "')\">...</a></li>";
            navigation_html += "<li><a href=\"javascript:next('"+scope+"');\"> > </a></li>";
            navigation_html += "<li class=\"next_link\"><a href=\"javascript:last_page('"+scope+"');\"> >> </a></li></ul>";
            $(scope).find('.page_navigation').html(navigation_html);
            
         }
    }

    $(scope).find('.sel_pagine').append("<button type=\"button\" class=\"btn btn-default dropdown-toggle\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\">Pag <strong>"+(page_num)+"</strong> <span class=\"caret\"></span></button><ul class=\"dropdown-menu lista_pagine\"></ul>");    
    popola_select(scope);

    $(scope).find(".page_link[longdesc='"+page_num+"']").addClass('active');

};

/* carico le pagine nel selettore */
function popola_select(scope){
    /*get the number of items shown per page*/
    var show_per_page = parseInt($(scope).find('#show_per_page').val());
    /*getting the amount of elements inside pagination_content div*/
    var number_of_items = parseInt($(scope).find('.pagination_content .paginated_element').size());
    /*calculate the number of pages we are going to have*/
    var number_of_pages = Math.ceil(number_of_items/show_per_page);

    for(pag=1; pag<=number_of_pages; pag++){
        $(".sel_pagine ul").append("<li><a href=\"javascript:go_to_page("+(pag)+",'"+scope+"')\">"+(pag)+"</a></li>");
    }
    
}

/* quando inizializzo il paginatore posso passare lo scope, cioè l'elemento in cui viene racchiuso il navigatore */
/* utile nel caso in cui ci siano più navigatori nella stessa pagina */

function init_paginatore(scope){
    if (scope === undefined) {
          scope = 'body';
    }

    /*how much items per page to show */
    var show_per_page = $(scope).find("#items_per_page").val();
    /* numero di pagine nella navigation bar */
    var max_page_in_navbar = $(scope).find("#max_page_in_navbar").val();
    /*getting the amount of elements inside pagination_content div*/
    //var number_of_items = $(scope).find('.pagination_content').children().size();
    var number_of_items = $(scope).find('.pagination_content .paginated_element').size();
    /*calculate the number of pages we are going to have*/
    var number_of_pages = Math.ceil(number_of_items/show_per_page);

    /*set the value of our hidden input fields*/
    $(scope).find('#current_page').val(0);
    $(scope).find('#show_per_page').val(show_per_page);
    popola_select(scope)

    var window_width = $( window ).width();
    var classi_paginatore = "pagination";
    var classi_selettore = "btn-group";
    if(window_width <= 768){
        classi_paginatore += " pagination-lg";
        classi_selettore += " btn-group-lg";
    }
    //$(window).resize(function() {};


    if(number_of_pages>1){

        var navigation_html = "<ul class='"+classi_paginatore+"'><li class=\"previous_link\"><a href=\"javascript:first_page('"+scope+"');\"> << </a></li>";
        navigation_html += "<li><a href=\"javascript:previous('"+scope+"');\"> < </a></li>";
        var current_link = 1;
        if(number_of_pages<max_page_in_navbar)
        {
            while(number_of_pages >= current_link){
                navigation_html += "<li class=\"page_link\" longdesc=\"" + current_link +"\"><a href=\"javascript:go_to_page(" + current_link +", '" + scope + "')\" >"+ (current_link) +"</a></li>";
                //navigation_html += '<li class="page_link" longdesc="' + current_link +'"><a href="javascript:go_to_page(' + current_link +', \"' + scope + '\")" >'+ (current_link + 1) +'</a></li></ul>';
                current_link++;
            }
        }
        else{
            while(current_link<=max_page_in_navbar){
                navigation_html += "<li class=\"page_link\" longdesc=\"" + current_link +"\"><a href=\"javascript:go_to_page(" + current_link +", '" + scope + "')\" >"+ (current_link) +"</a></li>";
                current_link++;
            }
            navigation_html += "<li class=\"page_link\" longdesc=\"...\"><a href=\"javascript:go_to_page("+current_link+", '" + scope + "')\">...</a></li>";
        }
        navigation_html += "<li><a href=\"javascript:next('"+scope+"');\"> > </a></li>";
        navigation_html += "<li class=\"next_link\"><a href=\"javascript:last_page('"+scope+"');\"> >> </a></li></ul>";

        $(scope).find('.page_navigation').html(navigation_html);

        /*add active class to the first page link*/
        $(scope).find('.page_navigation .page_link:first').addClass('active');

        /*hide all the elements inside pagination_content div*/
        /*$(scope).find('.pagination_content').children().css('display', 'none');*/
        $(scope).find('.pagination_content .paginated_element').hide();

        /*and show the first n (show_per_page) elements*/
        /*$(scope).find('.pagination_content').children().slice(0, show_per_page).css('display', 'block');*/
        $(scope).find('.pagination_content .paginated_element').slice(0, show_per_page).show();

        $(scope).find('.page_navigation').after("<div class=\""+classi_selettore+" dropup sel_pagine\"><button type=\"button\" class=\"btn btn-default dropdown-toggle\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\">Pag <strong>1</strong> <span class=\"caret\"></span></button><ul class=\"dropdown-menu lista_pagine\"></ul></div>");
        popola_select(scope);
    }


}


