function waitfor(hReceiver)

    Timeout  = class.Constants.Timeout;
    waitTime = tic;
    t = toc(waitTime);

    while t < Timeout
        if hReceiver.NumBytesAvailable
            break
        end
        t = toc(waitTime);
    end

    if ~hReceiver.NumBytesAvailable
        error('Não recebida resposta do instrumento em %d segundos...', Timeout)
    end
end