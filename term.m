function [term] = term(ucurve, vfir, vsec, cint, cslope, cageint, cageslope,...
                        conskid, Beta, wm, wf, nt, at, dmt, dft, y, t)
if dmt == 1 && dft == 1 && nt > 0
term=(Beta+Beta^2+Beta^3+Beta^4+Beta^5+Beta^6+Beta^7+Beta^8+Beta^9+Beta^10+Beta^11+Beta^12+Beta^13+Beta^14+Beta^15+Beta^16+Beta^17+Beta^18+Beta^19+Beta^20)*...
      (((max(wm + wf + y - conskid*nt,0)).^(1 - ucurve)) / (1 - ucurve) +  vfir .* nt - vsec .* nt^2) -...
          Beta*max(0, cint + cageint.*(t+1) - cslope .* (at+1) - cageslope .* (at+1) .* (t+1))-Beta^2*max(0, cint + cageint.*(t+2) - cslope .* (at+2) - cageslope .* (at+2) .* (t+2))-...
          Beta^3*max(0, cint + cageint.*(t+3) - cslope .* (at+3) - cageslope .* (at+3) .* (t+3))-Beta^4*max(0, cint + cageint.*(t+4) - cslope .* (at+4) - cageslope .* (at+4) .* (t+4));
elseif dmt == 1 && dft == 1 && nt == 0
term=(Beta+Beta^2+Beta^3+Beta^4+Beta^5+Beta^6+Beta^7+Beta^8+Beta^9+Beta^10+Beta^11+Beta^12+Beta^13+Beta^14+Beta^15+Beta^16+Beta^17+Beta^18+Beta^19+Beta^20)*(((max(wm + wf + y - conskid*nt,0)).^(1 - ucurve)) / (1 - ucurve) + ...
          vfir .* nt - vsec .* nt^2);
elseif dmt == 1 && dft == 0
term=(Beta+Beta^2+Beta^3+Beta^4+Beta^5+Beta^6+Beta^7+Beta^8+Beta^9+Beta^10+Beta^11+Beta^12+Beta^13+Beta^14+Beta^15+Beta^16+Beta^17+Beta^18+Beta^19+Beta^20)*(((max(wm + y - conskid*nt,0)).^(1 - ucurve)) / (1 - ucurve) + ...
          vfir .* nt - vsec .* nt^2);
elseif dmt == 0 && dft == 1
term=(Beta+Beta^2+Beta^3+Beta^4+Beta^5+Beta^6+Beta^7+Beta^8+Beta^9+Beta^10+Beta^11+Beta^12+Beta^13+Beta^14+Beta^15+Beta^16+Beta^17+Beta^18+Beta^19+Beta^20)*(((max(wf + y - conskid*nt,0)).^(1 - ucurve)) / (1 - ucurve) + ...
          vfir .* nt - vsec .* nt^2);
else     
term=(Beta+Beta^2+Beta^3+Beta^4+Beta^5+Beta^6+Beta^7+Beta^8+Beta^9+Beta^10+Beta^11+Beta^12+Beta^13+Beta^14+Beta^15+Beta^16+Beta^17+Beta^18+Beta^19+Beta^20)*(((max(y - conskid*nt,0)).^(1 - ucurve)) / (1 - ucurve) + ...
          vfir .* nt - vsec .* nt^2);
end

%=(Beta+Beta^2+Beta^3+Beta^4+Beta^5+Beta^6+Beta^7+Beta^8+Beta^9+Beta^10+Beta^11+Beta^12+Beta^13+Beta^14+Beta^15+Beta^16+Beta^17+Beta^18+Beta^19+Beta^20)*...