$(function() {
	var client = ZAFClient.init();
	client.invoke('resize', { width: '100%', height: '250px' });

	client.get('ticket.requester.id').then(
		function(data) {
			var user_id = data['ticket.requester.id'];
			requestUserInfo(client, user_id);
		}
	);
});

function formatDate(date) {
	var cdate = new Date(date);
	var options = {
		year: "numeric",
		month: "short",
		day: "numeric"
	};
	date = cdate.toLocaleDateString("en-us", options);
	return date;
}

function requestUserInfo(client, id) {
	var settings = {
		url: '/api/v2/users/' + id + '.json',
		type:'GET',
		dataType: 'json',
	};

	client.request(settings).then(
		function(zendesk_data) {

			$.getJSON(
				'/zendesk/customer?'+zendesk_query_string,
				{ email: zendesk_data.user.email, phone: zendesk_data.user.phone },
				function( server_data ){
					if ( server_data.status == 200 )
						showInfo(zendesk_data,server_data);
					else
						showNotFound(zendesk_data,server_data)
				}
			).fail( function(response) {
				showError(response)
			} )

		},
		function(response) {
			showError(response);
		}
	);
}

function showInfo(zendesk_data,server_data) {
	var requester_data = {
		'customer': {
			'name': zendesk_data.user.name,
			'email': zendesk_data.user.email,
			'tags': zendesk_data.user.tags,
			'url': server_data.url
		},
		'created_at': formatDate(zendesk_data.user.created_at),
		'last_login_at': formatDate(zendesk_data.user.last_login_at),
		'orders': null,
		'orders_count': server_data.orders_count,
		'orders_total': server_data.orders_total
    };

	$( server_data.orders || [] ).each(function(){
		requester_data.orders = requester_data.orders || []
		requester_data.orders.push( {
			'code': this.code,
			'url': this.url,
			'created_at': formatDate(this.created_at),
			'fulfillment_status': ( this.fulfilled_at ? 'fulfilled' : 'not_fulfilled' )
		} )
	})


	var source = $("#requester-template").html();
	var template = Handlebars.compile(source);
	var html = template(requester_data);
	$("#content").html(html);
}

function showNotFound(zendesk_data,server_data) {
	var source = $("#notfound-template").html();
	var template = Handlebars.compile(source);
	var html = template({});
	$("#content").html(html);
}

function showError(response) {
	var error_data = {
		'status': response.status,
		'statusText': response.statusText
	};
	var source = $("#error-template").html();
	var template = Handlebars.compile(source);
	var html = template(error_data);
	$("#content").html(html);
}
