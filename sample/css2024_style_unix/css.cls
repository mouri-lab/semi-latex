
% css.cls   2016.6.13 by Masayuki Terada (v1.00)
%           partially copied from ipsjtech.sty (by IPSJ)
% css.cls   2018.6.4 by HOSOI Takurou (v1.10)
%           partially copied from ipsjtech.sty and ipsj.cls (by IPSJ)
%             * for adding the foot part, 
%               with the copyright notion, without page numbers.
%             * This needs year number management: 
%               counter "volume" or "\ipsj@year".

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{css}
 [2016/06/13 v1.00 CSS class]

%% Article options
\DeclareOption{english}{
  \PassOptionsToClass{\CurrentOption}{ipsj}
}

\DeclareOption{noauthor}{
  \PassOptionsToClass{\CurrentOption}{ipsj}
}

%% Fallback
\DeclareOption*{
  \ClassWarning{css}{Unknown option '\CurrentOption'}
}

%% Process given options
\ProcessOptions\relax

%% Load base
\LoadClass[submit,techrep]{ipsj}

\def\ps@IPSJTITLEheadings{%
 \def\@oddhead{}%
 \let\@evenhead\@oddhead
%%%% %(changed: 2018-06-04(Mon.))% %%%%
%%%% \def\@oddfoot{}%
%%%% \def\@evenfoot{}%
 \def\@oddfoot{\@Lbot%
    \rlap{%
      {\bothashira%
%       {\textcopyrighttx} \ {\@footyear} Information Processing Society of Japan%
    }}%
    \hfil%
 \@Rbot}%
 \let\@evenfoot\@oddfoot
%%%% %(end of change: 2018-06-04(Mon.))% %%%%
}

\def\ps@headings{%
 \def\@oddhead{}%
 \let\@evenhead\@oddhead
%%%% %(changed: 2018-06-04(Mon.))% %%%%
%%%% \def\@oddfoot{}%
%%%% \def\@evenfoot{}%
 \def\@oddfoot{\@Lbot%
    \rlap{%
      {\bothashira%
%       {\textcopyrighttx} \ {\@footyear} Information Processing Society of Japan%
    }}%
    \hfil%
 \@Rbot}%
 \let\@evenfoot\@oddfoot
%%%% %(end of change: 2018-06-04(Mon.))% %%%%
}
\pagestyle{headings}

%%%% %(changed: 2018-06-04(Mon.))% %%%%
%%%% %(assignment by the defined counter)% %%%%
%%%% %(... this might be valid in the source file.)% %%%%
  \setcounter{volume}{59}%
%%%% %(direct assignment, ver.2)% %%%%
% \def\ipsj@year{2018}%
%%%% %(direct assignment, ver.1)% %%%%
\def\ipsj@year{\c@year2019 \number\c@year}%
%%%% %(added: 2019-06-07(Fri.))% %%%%
%%%% %(definition in ipsj.cls)% %%%%
% \def\ipsj@year{\c@year1959 \advance\c@year\c@volume}%
%%%% %(end of change: 2018-06-04(Mon.))% %%%%

\endinput
