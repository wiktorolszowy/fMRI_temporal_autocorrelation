function print_to_svg_to_pdf(figname, path_manage)
   cd([path_manage '/figures']);
   print (figname, '-dsvg');
   system(['rsvg-convert -f pdf -o ' figname '.pdf ' figname '.svg']);
   system(['rm ' figname '.svg']);
   system(['pdfcrop ' figname '.pdf ' figname '.pdf']);
   cd(path_manage);
end

