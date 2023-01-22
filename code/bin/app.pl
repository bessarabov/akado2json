#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use utf8;
use open qw(:std :utf8);

use JSON::PP;
use HTTP::Tiny;
use Path::Tiny;
use Data::Dumper;
use JSON::Validator;
use HTTP::Request::Common;
use LWP::UserAgent;
use XML::Simple;

use Utils;

sub get_input_data {
    my ($input_file_name) = @_;

    die "No file $input_file_name" if not -e $input_file_name;

    my $input_content = path($input_file_name)->slurp();
    my $input_data = {};

    eval {
        $input_data = decode_json $input_content;
    };

    if ($@) {
        die "Can't parse json from $input_file_name";
    }

    my $jv = JSON::Validator->new();
    $jv->schema('file:///app/data/input_schema.json');
    my @errors = $jv->validate($input_data);

    if (@errors) {
        die "Content of file $input_file_name does not match schema:\n@errors";
    }

    return $input_data;
}

sub get_xml {
    my (%h) = @_;

    my $login = delete $h{login};
    die 'no login' if not defined $login;

    my $password = delete $h{password};
    die 'no password' if not defined $password;

    my $browser = LWP::UserAgent->new;

    $browser->agent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36');
    $browser->cookie_jar( {} );

    my $request = POST(
    	'https://office.akado.ru/user/login.xml',
        Content => [
            login    => $login,
            password => $password,
        ]
    );

    my $response = $browser->request($request);

	if ($response->is_success) {
		my $xml = $response->decoded_content();
		return $xml;
	} else {
		die "Can't login to akado: " .  $response->status_line();
	}
}

sub get_balance {
    my ($xml) = @_;

#<?xml version="1.0" encoding="UTF-8"?>
#<?akado-request XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX?>
#<main responseType="accepted" current-time="22.01.2023 13:32:35" redirect="/application/main.xml?requestID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX">
#  <account surname="Фамилия" name="Имя" patronymic="Отчество" balance="642.56" crc="1111111" splashes="0" prepay="-1" billing="2" personal_data_agreement="1">
#    <mail address="email@example.com"/>
#  </account>
#  <message>Вы успешно вошли в Личный кабинет. Пожалуйста, подождите.</message>
#</main>

    my $data = XMLin($xml);
    my $balance;

    eval {
        $balance = $data->{account}->{balance};
    };

    if (defined($balance) && $balance > -10_000 && $balance < 10_000) {
        return(sprintf('%.2f', $balance) + 0);
    } else {
        die "Can't get info about balance";
    }
}

sub write_output {
    my ($balance) = @_;

    path('/output/output.json')->spew(to_pretty_json({
        is_success => JSON::PP::true,
        balance => $balance,
    }));
}

sub main {

    my $input_file_name = '/input/input.json';

    my $input_data = get_input_data($input_file_name);

    my $xml = get_xml(
        login => $input_data->{login},
        password => $input_data->{password},
    );

    my $balance = get_balance($xml);

    write_output($balance);

}
main();
