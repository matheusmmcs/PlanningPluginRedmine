(function($){
	$(document).ready(function(){

		var $users = $('.planning-user'),
			$filterName = $('[name="filtro-username"]'),
			users = [];

		$users.each(function(){
			var $this = $(this);
			var groupsInfo = $this.find('[name="user-groups-info"]').val().trim().split(',');
			var userName = $this.find('.user').html(); 
			users.push({
				name: userName,
				nameNormalized: normalizeString(userName),
				groups: groupsInfo,
				element: $this,
				active: true,
				countIssuesOpened : Number.parseInt($this.attr('data-issues-opened')),
				countIssuesOverdue : Number.parseInt($this.attr('data-issues-overdue')),
				countIssuesUnplanned : Number.parseInt($this.attr('data-issues-unplanned'))
			});
			$this.addClass('planning-user--active-animation');
		});

		function normalizeString(str, preserveCaracters) {
		    str = str.toUpperCase();
		    str = str.replace(/[ÀÁÂÃ]/g,"A");
		    str = str.replace(/[ÈÉÊ]/g,"E");
		    str = str.replace(/[ÍÌÎ]/g,"I");
		    str = str.replace(/[ÓÒÔÕ]/g,"O");
		    str = str.replace(/[ÚÙÛ]/g,"U");
		    str = str.replace(/[Ç]/g,"C");
		    if (preserveCaracters !== true) {
		        str = str.replace(/[^A-Z0-9]/gi,'');
		    }
		    return str;
		}

		var initialize = function() {
			filterUsers();
		}

		var filterUsers = function() {
			var unidades = [],
				filterName = normalizeString($filterName.val());

			$('[name="filtro-unidades"]:checkbox').each(function(){
				if ($(this).is(":checked")) {
					unidades.push($(this).val());
				}
			});

			var filterIssue = $('[name="filtro-issues"]').val();

			//reset active
			for (var u in users) {
				users[u].active = false;
			}

			//filtrar por unidades
			if (unidades.length) {
				for (var i in unidades) {
					var unidade = unidades[i];
					for (var u in users) {
						var user = users[u];
						if (user.groups.indexOf(unidade) != -1) {
							user.active = true;
						}
					}
				}
			} else {
				for (var u in users) {
					users[u].active = true;
				}
			}

			//filtrar por nome
			if (filterName.length) {
				for (var u in users) {
					var user = users[u];
					if (user.active && user.nameNormalized.indexOf(filterName) == -1) {
						user.active = false;
					}
				}
			}

			//filter by issues opened
			if (filterIssue > 0) {
				for (var u in users) {
					var user = users[u];
					//none
					if ((filterIssue == 1 && user.countIssuesOpened > 0) ||
						(filterIssue == 2 && user.countIssuesOpened == 0) ||
						(filterIssue == 3 && user.countIssuesOverdue == 0) ||
						(filterIssue == 4 && user.countIssuesUnplanned == 0)
					) {
						user.active = false;
					}
				}
			}
			//countIssuesOpened

			//re-render usuarios
			for (var u in users) {
				var user = users[u];
				if (user.active) {
					user.element.show();
				} else {
					user.element.hide();
				}
			}
		}

		$('select[name="filtro-issues"]').change(function(e) {
			filterUsers();
		});

		$('[name="filtro-unidades"]:checkbox').change(function(e) {
			filterUsers();
		});

		$('[name="filtro-username"]').on('keyup', function(e){
			filterUsers();
		});

		$('.planning-user-details').on('click', function(e) {
			e.preventDefault();
			var $this = $(this),
				$planningUser = $this.closest('.planning-user'),
				openClass = 'planning-user--active';

			if ($planningUser.hasClass(openClass)) {
				$planningUser.removeClass(openClass);
				$this.next().hide();
				$this.removeClass('arrow_up');
				$this.addClass('arrow_down');
			} else {
				$planningUser.addClass(openClass);
				$this.next().show();
				$this.addClass('arrow_up');
				$this.removeClass('arrow_down');
			}				
		});

		$('.planning-legend-close').on('click', function(e) {
			e.preventDefault();
			$('#legend').hide(); 
			$('#label_open_button').show();
		});

		$('#label_open_button').on('click', function(e) {
			e.preventDefault();
			$('#legend').show(); 
			$(this).hide();
		});

		/* Abrir / Fechar todas as tarefas */
		$('.planning-expand-form').on('click', function(e) {
			e.preventDefault();
			openIssuesDetails();
			$('.planning-expand-form').addClass('u-hide');
			$('.planning-compress-form').removeClass('u-hide');
		});

		$('.planning-compress-form').on('click', function(e) {
			e.preventDefault();
			closeIssuesDetails();
			$('.planning-compress-form').addClass('u-hide');
			$('.planning-expand-form').removeClass('u-hide');
		});

		function openIssuesDetails() {
			$('.planning-user-details.arrow_down').each(function(){
				$(this).click();
			});
		}

		function closeIssuesDetails() {
			$('.planning-user-details.arrow_up').each(function(){
				$(this).click();
			});
		}


		/* pattern to format date */
		$('.datepicker-here').formatter({
		  'pattern': '{{99}}/{{99}}/{{9999}}',
		  'persistent': false
		});

		/* Chosen config */
		$('.chosen-select').chosen({
			no_results_text:'Oops, sem resultados!',
			allow_single_deselect: true
			//disable_search_threshold: 10,
		});

		/* Clear form */
	    $('.planning-reset-form').on('click', function (e) {
	    	e.preventDefault();
	        $(this).closest('form')
	            .find(':radio, :checkbox').removeAttr('checked').end()
	            .find('textarea, :text, select').val('');

	        console.log($(this).closest('form').find('.chosen-select'))
	        $(this).closest('form').find('.chosen-select').val(null).trigger('chosen:updated');

	        return false;
	    });


	    initialize();

	});
})(jQuery);